//
//  Config.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/13.
//

import Foundation
// MARK: - 後端設定
enum Config {
    /// 後端 Base URL，可在 Xcode Scheme 的 Environment Variables 設定 `BACKEND_BASE_URL` 覆蓋
    static let backendBaseURL: String = {
        if let v = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"], !v.isEmpty { return v }
        return "http://127.0.0.1:8000"
    }()

    /// 全域請求逾時秒數（可依機型與模型速度調整）
    static let requestTimeout: TimeInterval = 30
    /// 短重試次數（e.g. 後端冷啟）
    static let retryCount = 1
    /// 重試間隔
    static let retryDelay: TimeInterval = 0.8
}
