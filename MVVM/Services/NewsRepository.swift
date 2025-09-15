//
//  NewsRepository.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

// MARK: - 資料存取中樞（Repository）
// 流程：先檢查記憶體快取 → SingleFlight 合併 → RateLimiter 節流 → NewsService 打 API → Sentiment 本地評分 → 回存快取
final class NewsRepository {
    private let service: NewsServiceProtocol
    private let sentiment: SentimentServiceProtocol
    private let limiter = RateLimiter(perSecond: 2, perMinute: 30)
    private let flights = SingleFlight<[SentimentDay]>()
    private let memoryCache = NSCache<NSString, NSArray>()

    // ← 新增：把「今天算出的關鍵字」暫存在這裡，讓 VM 讀
    private(set) var lastKeywords: [String] = []

    init(service: NewsServiceProtocol, sentiment: SentimentServiceProtocol) {
        self.service = service
        self.sentiment = sentiment
    }
    


    // 近 N 天的每日情緒：
    //   - 今天：用 headline + summary（全文）做情緒分析，並產出 top 5 keywords
    //   - 非今天（但在這 N 天內）：只用 headline 做情緒分析（省流量）
    func dailySentiments(symbol: String, days: Int) async throws -> [SentimentDay] {
        let key = "\(symbol)-\(days)" as NSString
        if let cached = memoryCache.object(forKey: key) as? [SentimentDay] { return cached }

        return try await flights.run(key: key as String) { [weak self] in
            guard let self else { return [] }

            self.lastKeywords = []  // ← 每次重新計算先清空，避免沿用上次

            var result: [SentimentDay] = []
            let today = Date()

            for i in (0..<days).reversed() {
                try Task.checkCancellation()
                let day = Calendar.current.date(byAdding: .day, value: -i, to: today)!
                let dateOnly = Calendar.current.startOfDay(for: day)

                // 抓單日新聞（由 RateLimiter 節流，避免爆量）
                let items = try await self.limiter.runWithRetry {
                    try await self.service.companyNews(symbol: symbol, from: dateOnly, to: dateOnly)
                }

                if Calendar.current.isDateInToday(dateOnly) {
                    let texts = items.map { [$0.headline, $0.summary ?? ""].joined(separator: " ") }
                    let score = self.sentiment.scoreFullTexts(texts: texts)
                    self.lastKeywords = self.sentiment.topKeywords(from: texts, topK: 5)
                    result.append(SentimentDay(date: dateOnly, count: texts.count, score: score))
                } else {
                    let headlines = items.map { $0.headline }
                    let score = self.sentiment.score(headlines: headlines)
                    result.append(SentimentDay(date: dateOnly, count: headlines.count, score: score))
                }
            }

            self.memoryCache.setObject(result as NSArray, forKey: key)
            return result
        }
    }
    
    
}
