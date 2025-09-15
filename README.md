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

---

## 🚀 Getting Started
