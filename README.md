# 📈 SentimentStocks

**SentimentStocks** is an iOS application that combines **on-device sentiment analysis** with an **AI-powered investment advice backend**.  
It provides stock-specific insights by analyzing financial news, extracting keywords, and augmenting a lightweight LLM with financial context.

---

## ✨ Features

- **📊 Stock List & Search**  
  Browse and search U.S. equities using a clean, stock-app-like interface.

- **📰 On-Device Sentiment Analysis**  
  Uses Apple’s **NLLanguage** APIs to classify daily news as **Optimistic**, **Neutral**, or **Pessimistic** directly on the device.  
  This avoids latency and improves privacy.

- **🤖 AI-Powered Investment Advice**  
  - Backend built with **Python FastAPI**  
  - Powered by **Gemma-2B** running locally via **Ollama**  
  - Enhanced with **LlamaIndex** and **RAG (Retrieval-Augmented Generation)** to ground responses in real financial news  
  - Provides 3 concise, actionable English suggestions for each stock

- **🔑 Keyword Extraction for RAG**  
  Extracts daily keywords from headlines and articles (e.g., *inflation, earnings, supply chain*) and feeds them into RAG to strengthen context for Gemma.

- **⚙️ MVVM Architecture**  
  SwiftUI frontend built with **MVVM** for clean separation of concerns and testability.

- **🌐 Real Market Data**  
  Integrates with **Finnhub API** for real-time stock symbols and news feeds.

---

## 🛠 Tech Stack

### Frontend (iOS)
- **Swift / SwiftUI**
- **MVVM architecture**
- **NLLanguage** for sentiment analysis
- **Async/Await networking**
- **Custom Palette gradient UI**

### Backend (API)
- **Python FastAPI**
- **Gemma-2B LLM** (via **Ollama**)
- **LlamaIndex** + **RAG** for retrieval-augmented answers
- **SentenceTransformers / NLP** for keyword extraction
- **Finnhub API** for stock & news data

## 📱 Demo

![App Demo](https://github.com/Jerrywu108150/Sentiment-Stocks-APP.git/main/Display.gif)
---

## Getting Started

This project has two main parts:

- **iOS App (SwiftUI + MVVM)**  
  Performs local sentiment analysis on stock news headlines/summaries using `NLLanguage` and displays per-stock scores and keywords.  
  It also calls a backend service for LLM-based investment advice.

- **Backend (Python FastAPI + Gemma 2B with RAG)**  
  Provides additional investment advice by combining LlamaIndex-powered Retrieval-Augmented Generation (RAG) with an open-source LLM (`gemma:2b` running via Ollama).

---

### 1. Backend Setup

First, make sure you have [pyenv](https://github.com/pyenv/pyenv) installed.  
Then create a clean Python environment:

```bash
# go to backend folder
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Ollama&Gemma install
brew install ollama
ollama serve            
ollama pull gemma2:2b

#Then you can run backend
uvicorn app:app --reload --port 8000
#And test with new terminal
curl -X POST http://127.0.0.1:8000/advice_rag \
  -H "Content-Type: application/json" \
  -d '{"symbol":"AAPL","level":"Pessimistic","keywords":["inflation","earnings"],"score":-0.3}'
```

### 2. iOS App Setup
  1.	Open SentimentStocks.xcodeproj in Xcode 15+.
	2.	Make sure you are running on iOS 17+ (for NLLanguage.sentimentScore).**
	3.	Update your Finnhub API token:
	•	In Dependencies.makeRepository(), replace the placeholder token with your own.
	•	You can get a free token at https://finnhub.io.
News are analyzed locally for sentiment and top keywords.
LLM advice is fetched from your running backend.

### 3. Running Everything
  • Start the backend server (uvicorn ...)
	•	Run the iOS app in Xcode simulator or on device
	•	Search for a stock → open detail → sentiment analysis and AI advice will be displayed
