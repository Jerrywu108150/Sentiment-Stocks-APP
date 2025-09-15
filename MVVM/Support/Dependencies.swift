//
//  Dependencies.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

// MARK: - 簡單的依賴注入工廠
// 目的：在 App 啟動或 View 初始化時，統一決定要用真實服務還是假的（例如 UI 測試）。
enum Dependencies {
    static func makeRepository() -> NewsRepository {
        // UI 測試會把這個環境變數設為 "1"，我們就回傳 Mock 版本
        let useMock = ProcessInfo.processInfo.environment["UITESTS_USE_MOCK"] == "1"

        if useMock {
            let service = MockNewsService()               // 內建於 App target 的假服務（見下方）
            let sentiment = SentimentService()
            return NewsRepository(service: service, sentiment: sentiment)
        } else {
            // 正常模式：使用 Finnhub
            let token = ProcessInfo.processInfo.environment["FINNHUB_TOKEN"] ?? "d2v8ts9r01qq994inc40d2v8ts9r01qq994inc4g"
            let service = NewsService(token: token)
            let sentiment = SentimentService()
            return NewsRepository(service: service, sentiment: sentiment)
        }
    }
    
    static func makeTickerRepository() -> TickerRepository {
            let token = ProcessInfo.processInfo.environment["FINNHUB_TOKEN"] ?? "d2v8ts9r01qq994inc40d2v8ts9r01qq994inc4g"
            let svc = TickerService(token: token)
            return TickerRepository(service: svc)
        }
    
    static func makeAdviceClient() -> AdviceClientProtocol {
            let useAdviceMock = ProcessInfo.processInfo.environment["UITESTS_USE_ADVICE_MOCK"] == "1"
            if useAdviceMock {
                return MockAdviceClient()
            } else {
                return AdviceClient(baseURLString: Config.backendBaseURL)
            }
        }
}

// MARK: - App 內建「假」新聞服務（供 UITests 用）
// 注意：放在 App target 才能在執行期被使用；UI 測試只負責把環境變數打開。
final class MockNewsService: NewsServiceProtocol {
    func companyNews(symbol: String, from: Date, to: Date) async throws -> [NewsItem] {
        // 以日期為種子，回傳可重現的 headlines；確保測試穩定
        let k = Calendar.current.ordinality(of: .day, in: .era, for: from) ?? 0
        let sample: [[String]] = [
            ["\(symbol) beats expectations in Q report", "Analyst upgrades \(symbol) on strong outlook"],
            ["\(symbol) faces supply chain pressure", "Market uncertainty weighs on \(symbol)"],
            ["\(symbol) launches new product line", "Customers praise \(symbol)'s service improvements"]
        ]
        let headlines = sample[k % sample.count]
        return headlines.map { NewsItem(headline: $0, date: from, url: nil, summary: "Mock summary for UI test") }
    }
}
