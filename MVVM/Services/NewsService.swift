//
//  NewsService.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

// MARK: - 定義新聞服務協議（介面）
protocol NewsServiceProtocol {
    func companyNews(symbol: String, from: Date, to: Date) async throws -> [NewsItem]
}

final class NewsService: NewsServiceProtocol {
    private let base = URL(string: "https://finnhub.io/api/v1")!
    private let token: String

    init(token: String) { self.token = token }

    func companyNews(symbol: String, from: Date, to: Date) async throws -> [NewsItem] {
        var comps = URLComponents(url: base.appendingPathComponent("company-news"), resolvingAgainstBaseURL: false)!
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate] // 只要日期

        comps.queryItems = [
            .init(name: "symbol", value: symbol),
            .init(name: "from", value: df.string(from: from)),
            .init(name: "to",   value: df.string(from: to)),
            .init(name: "token", value: token)
        ]

        let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        // Finnhub company-news 常見欄位：headline, datetime(秒), url, summary
        struct Raw: Decodable {
            let headline: String
            let datetime: TimeInterval
            let url: String?
            let summary: String?   // ← 新增
        }

        let raws = try JSONDecoder().decode([Raw].self, from: data)

        return raws.map { r in
            NewsItem(
                headline: r.headline,
                date: Date(timeIntervalSince1970: r.datetime),
                url: r.url.flatMap(URL.init(string:)),
                summary: r.summary     // ← 帶到我們的模型
            )
        }
    }
}
