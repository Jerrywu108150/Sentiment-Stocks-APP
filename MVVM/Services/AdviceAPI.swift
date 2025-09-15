//
//  AdviceAPI.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/15.
//

import Foundation

// MARK: - Advice API 的請求/回應模型
struct AdviceRequestPayload: Codable {
    let symbol: String
    let level: String          // "Optimistic" / "Neutral" / "Pessimistic"
    let keywords: [String]
    let score: Double
}

struct AdviceResponsePayload: Codable {
    let suggestions: [String]
}

// MARK: - 端點模式
enum AdviceMode {
    case rag        // /advice_rag
    case noRag      // /advice_no_rag

    var path: String {
        switch self {
        case .rag:   return "advice_rag"
        case .noRag: return "advice_no_rag"
        }
    }
}

// MARK: - Protocol 方便注入與測試
protocol AdviceClientProtocol {
    func fetchAdvice(
        mode: AdviceMode,
        symbol: String,
        level: String,
        keywords: [String],
        score: Double
    ) async throws -> [String]
}

// MARK: - 真實 HTTP Client（URLSession async/await）
final class AdviceClient: AdviceClientProtocol {

    private let base: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURLString: String = Config.backendBaseURL, session: URLSession? = nil) {
        guard let url = URL(string: baseURLString) else { fatalError("Invalid backend URL") }
        self.base = url

        // 自訂 session：逾時比較長一些（Gemma 本地可能慢）
        if let session = session {
            self.session = session
        } else {
            let cfg = URLSessionConfiguration.default
            cfg.timeoutIntervalForRequest = Config.requestTimeout
            cfg.timeoutIntervalForResource = Config.requestTimeout
            self.session = URLSession(configuration: cfg)
        }

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase   // 對應常見 snake_case。 [oai_citation:1‡Apple Developer](https://developer.apple.com/documentation/foundation/jsondecoder/keydecodingstrategy-swift.enum/convertfromsnakecase?utm_source=chatgpt.com)
        self.decoder = dec
    }

    func fetchAdvice(
        mode: AdviceMode,
        symbol: String,
        level: String,
        keywords: [String],
        score: Double
    ) async throws -> [String] {

        var req = URLRequest(url: base.appendingPathComponent(mode.path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(
            AdviceRequestPayload(symbol: symbol, level: level, keywords: keywords, score: score)
        )

        // 簡單重試：遇到瞬時錯誤/冷啟延遲時再試一次
        var attempt = 0
        while true {
            attempt += 1
            do {
                try Task.checkCancellation() // 支援取消（例如返回上一頁）。 [oai_citation:2‡SwiftLee](https://www.avanderlee.com/concurrency/tasks/?utm_source=chatgpt.com)
                let (data, resp) = try await session.data(for: req) // async/await URLSession。 [oai_citation:3‡Apple Developer](https://developer.apple.com/documentation/Foundation/URLSession?utm_source=chatgpt.com)
                guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                    throw URLError(.badServerResponse)
                }
                let payload = try decoder.decode(AdviceResponsePayload.self, from: data) // Codable 解碼。 [oai_citation:4‡Apple Developer](https://developer.apple.com/documentation/foundation/jsondecoder?utm_source=chatgpt.com)
                return payload.suggestions
            } catch {
                if attempt <= Config.retryCount {
                    try? await Task.sleep(nanoseconds: UInt64(Config.retryDelay * 1_000_000_000))
                    continue
                }
                throw error
            }
        }
    }
}

// MARK: - 假客戶端（UI 測試/離線）
final class MockAdviceClient: AdviceClientProtocol {
    var stubbed: [String] = [
        "Review risk exposure and avoid impulsive trades.",
        "Validate news with multiple reputable sources.",
        "Prefer gradual adjustments over immediate large moves."
    ]
    func fetchAdvice(mode: AdviceMode, symbol: String, level: String, keywords: [String], score: Double) async throws -> [String] {
        return stubbed
    }
}
