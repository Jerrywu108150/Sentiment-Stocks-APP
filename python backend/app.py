# app.py
import os, datetime as dt, requests
from typing import List
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# LlamaIndex & Vector store & Embeddings
from llama_index.core import Document, VectorStoreIndex, Settings
from llama_index.core.node_parser import SentenceSplitter
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.llms.ollama import Ollama
from chromadb import PersistentClient

load_dotenv()

FINNHUB = os.getenv("FINNHUB_TOKEN", "d2v8ts9r01qq994inc40d2v8ts9r01qq994inc4g")
OLLAMA  = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL   = os.getenv("LLM_MODEL", "gemma2:2b")

app = FastAPI(title="Advice (LlamaIndex + Gemma2)")
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

# ---- LlamaIndex 全域設定 ----
Settings.llm = Ollama(model=MODEL, base_url=OLLAMA, request_timeout=60)
Settings.embed_model = HuggingFaceEmbedding(model_name="sentence-transformers/all-MiniLM-L6-v2")

# ---- Chroma 向量庫（持久化，可重用）----
CHROMA_DIR = "./vectordb"
chroma_client = PersistentClient(path=CHROMA_DIR)

def upsert_symbol_corpus(symbol: str, day: dt.date) -> VectorStoreIndex:
    """
    動態抓今天的公司新聞，轉 Document，切塊、嵌入，upsert 到向量庫。
    回傳對應的 LlamaIndex。
    """
    # 1) 抓 Finnhub（今天），也可改抓近 3~7 天
    if not FINNHUB:
        # 沒金鑰：回 mock 兩則
        news = [
            dict(title=f"{symbol} beats expectations in Q report",
                 summary="Strong guidance; market reacted positively.", url=None),
            dict(title=f"Analyst upgrades {symbol} on outlook",
                 summary="Raised target price amid demand strength.", url=None),
        ]
    else:
        url = "https://finnhub.io/api/v1/company-news"
        params = {"symbol": symbol, "from": day.isoformat(), "to": day.isoformat(), "token": FINNHUB}
        r = requests.get(url, params=params, timeout=20)
        r.raise_for_status()
        data = r.json()
        news = []
        for x in data:
            news.append(dict(
                title=x.get("headline",""),
                summary=x.get("summary") or "",
                url=x.get("url"),
            ))

    # 2) 轉 Document
    docs = []
    for item in news:
        body = (item["title"] + "\n" + item["summary"]).strip()
        if not body:
            continue
        docs.append(Document(text=body, metadata={"url": item["url"], "symbol": symbol, "date": day.isoformat()}))

    # 3) 切塊
    splitter = SentenceSplitter(chunk_size=500, chunk_overlap=50)
    nodes = splitter.get_nodes_from_documents(docs)

    # 4) 以「symbol 為 collection」建立/取得向量庫並 upsert
    collection = chroma_client.get_or_create_collection(name=f"news_{symbol}")
    vector_store = ChromaVectorStore(chroma_collection=collection)
    index = VectorStoreIndex.from_vector_store(vector_store=vector_store)
    index.insert_nodes(nodes)  # upsert 新聞
    return index

# ---- 產生建議的 prompt（可共用）----
ADVICE_SYSTEM = "You are a prudent, concise assistant for retail investors."
def build_user_prompt(symbol: str, level: str, score: float, keywords: List[str], context: str | None) -> str:
    ctx = f"\nContext:\n{context}\n" if context else ""
    keys = ", ".join(keywords) if keywords else "n/a"
    return f"""{ctx}
Sentiment today for {symbol}: {level} (score {score:.2f})
Top keywords: {keys}

Write exactly 3 concise, numbered English suggestions for a cautious retail investor.
Each item one sentence (<= 20 words). Not financial advice.
""".strip()

# ---- 請求/回應模型 ----
class AdviceReq(BaseModel):
    symbol: str
    level: str
    keywords: List[str]
    score: float

class AdviceResp(BaseModel):
    suggestions: List[str]

def to_three_bullets(text: str) -> List[str]:
    lines = [ln.strip(" -•\t") for ln in text.split("\n") if ln.strip()]
    bullets = [ln for ln in lines if ln.startswith(("1.","2.","3.")) or (len(ln)>1 and ln[:1].isdigit())]
    if not bullets:
        bullets = lines
    # 去掉前綴編號
    out = []
    for ln in bullets[:3]:
        if ln[:2].isdigit() and ln[1] in (".",")"): ln = ln[2:].strip()
        elif ln[:1].isdigit(): ln = ln[1:].strip(" .)")
        out.append(ln)
    # 保底 3 條
    while len(out) < 3:
        out.append("Consider gradual, risk-aware adjustments rather than abrupt trades.")
    return out[:3]

# ---- 非 RAG ：直接問 LLM ----
@app.post("/advice_no_rag", response_model=AdviceResp)
def advice_no_rag(req: AdviceReq):
    if req.level not in {"Optimistic","Neutral","Pessimistic"}:
        raise HTTPException(400, "invalid level")
    llm = Settings.llm
    prompt = build_user_prompt(req.symbol, req.level, req.score, req.keywords, context=None)
    text = llm.complete(f"{ADVICE_SYSTEM}\n\n{prompt}").text
    return AdviceResp(suggestions=to_three_bullets(text))

# ---- RAG ：手動檢索 + 拼接 context ----
@app.post("/advice_rag", response_model=AdviceResp)
def advice_rag(req: AdviceReq):
    if req.level not in {"Optimistic","Neutral","Pessimistic"}:
        raise HTTPException(400, "invalid level")
    today = dt.date.today()
    index = upsert_symbol_corpus(req.symbol, today)
    qe = index.as_query_engine(similarity_top_k=3)

    # 1) 檢索：取前 k 個片段
    nodes = qe.retrieve(f"Recent investment news about {req.symbol}")
    context_text = "\n".join([n.get_content() for n in nodes]) if nodes else "(no context)"

    # 2) 拼接完整 prompt
    llm = Settings.llm
    final_prompt = build_user_prompt(
        req.symbol,
        req.level,
        req.score,
        req.keywords,
        context=context_text
    )

    # 3) 呼叫 LLM
    text = llm.complete(f"{ADVICE_SYSTEM}\n\n{final_prompt}").text

    # 4) 轉換成三條建議（保底）
    return AdviceResp(suggestions=to_three_bullets(text))


@app.get("/health")
def health():
    return {"ok": True, "model": MODEL, "ollama": OLLAMA}
