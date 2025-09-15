//
//  TickerService.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/12.
//

import Foundation

// Study: 定義抓「美股代號清單」的介面，之後要換來源（Polygon、IEX…）也容易
protocol TickerServiceProtocol {
    func fetchUSTickers() async throws -> [Ticker]
}

final class TickerService: TickerServiceProtocol {
    private let base = URL(string: "https://finnhub.io/api/v1")!
    private let token: String

    init(token: String) { self.token = token }

    // Study: Finnhub 回傳很多欄位，我們只挑 symbol/description
    struct Raw: Decodable {
        let symbol: String
        let description: String
        let type: String?
        let currency: String?
    }

    func fetchUSTickers() async throws -> [Ticker] {
        var comps = URLComponents(url: base.appendingPathComponent("stock/symbol"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "exchange", value: "US"),
            .init(name: "token", value: token)
        ]
        let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let raws = try JSONDecoder().decode([Raw].self, from: data)

        // Study: 做一些基本清洗（只保留常見股票，過濾權證/基金…）
        let filtered = raws.filter { raw in
            // 常見：type == "Common Stock" 或 type 為空；排除 “-” 無效描述
            let okType = (raw.type?.lowercased().contains("common") ?? true)
            let okDesc = !raw.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return okType && okDesc
        }

        // Study: 映射到我們的 Domain Model
        return filtered.map { Ticker(symbol: $0.symbol, name: $0.description) }
    }
}
