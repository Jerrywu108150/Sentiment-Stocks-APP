//
//  Models.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

struct Ticker: Identifiable, Codable, Hashable {
    var id: String { symbol }
    let symbol: String
    let name: String
}

// 加上 summary（Finnhub company-news 提供；拿來做「今天」的全文情緒分析）
struct NewsItem: Codable, Hashable {
    let headline: String
    let date: Date
    let url: URL?
    let summary: String?   // ← 新增：用來組合「headline + summary」做全文分析（今天）
}

struct SentimentDay: Codable, Hashable {
    let date: Date
    let count: Int
    let score: Double  // -1...+1
    var level: String {
        if score > 0.2 { return "Optimistic" }
        if score < -0.2 { return "Pessimistic" }
        return "Neutral"
    }
}
