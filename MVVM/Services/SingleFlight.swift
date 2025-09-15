//
//  SingleFlight.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

// MARK: - 合併同 key 請求（Actor）
// 解決：同時間對同一 symbol/天數重複打 API（例如多個 View 同時載入）
// 只會真的執行一次，其餘等待同一結果。
actor SingleFlight<T> {
    private var tasks: [String: Task<T, Error>] = [:]

    func run(key: String, operation: @escaping () async throws -> T) async throws -> T {
        if let existing = tasks[key] { return try await existing.value }
        let task = Task { try await operation() }
        tasks[key] = task
        defer { tasks[key] = nil }
        return try await task.value
    }
}
