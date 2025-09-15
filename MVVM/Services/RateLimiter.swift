//
//  RateLimiter.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

// MARK: - 節流器（Actor）
// 解決：Finnhub API 被一次連發導致 429/卡住
// 做法：限制每秒/每分鐘的請求數；runWithRetry 包一層指數退避重試。
actor RateLimiter {
    private let perSecond: Int
    private let perMinute: Int
    private var secondBucket: [Date] = []
    private var minuteBucket: [Date] = []

    init(perSecond: Int = 2, perMinute: Int = 30) {
        self.perSecond = perSecond
        self.perMinute = perMinute
    }

    // 取得配額：若超過就 sleep 等待，直到可用
    func acquire() async {
        while true {
            let now = Date()
            secondBucket = secondBucket.filter { now.timeIntervalSince($0) < 1.0 }
            minuteBucket = minuteBucket.filter { now.timeIntervalSince($0) < 60.0 }
            if secondBucket.count < perSecond && minuteBucket.count < perMinute {
                secondBucket.append(now); minuteBucket.append(now)
                return
            }
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
        }
    }

    // 包裝任務：先 acquire，再執行；失敗則退避重試
    func runWithRetry<T>(_ block: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        while true {
            try Task.checkCancellation()
            await acquire()
            do { return try await block() }
            catch {
                attempt += 1
                guard attempt <= 4 else { throw error }
                let delay = min(3.0, 0.3 * pow(2, Double(attempt))) // 0.3s→0.6s→1.2s→2.4s
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
}
