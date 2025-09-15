//
//  TickerRepository.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/12.
//

import Foundation

// Study: 把來源包起來：先看記憶體快取 → 沒有才打 API（並用 RateLimiter 控制節奏）
final class TickerRepository {
    private let service: TickerServiceProtocol
    private let limiter = RateLimiter(perSecond: 1, perMinute: 30)   // Finnhub 免費額度請酌量
    private var cache: [Ticker]?

    init(service: TickerServiceProtocol) {
        self.service = service
    }

    func allUSTickers() async throws -> [Ticker] {
        if let cache { return cache }
        let items = try await limiter.runWithRetry {
            try await self.service.fetchUSTickers()
        }
        self.cache = items
        return items
    }
}
