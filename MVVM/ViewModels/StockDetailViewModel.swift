//
//  StockDetailViewModel.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

// MARK: - 個股詳情 VM：抓 7 天資料，並在主執行緒驅動 UI
@MainActor
final class StockDetailViewModel: ObservableObject {
    @Published var today: SentimentDay?
    @Published var agg7: (avg: Double, level: String, days: [SentimentDay])?
    @Published var adviceSuggestions: [String] = []
    @Published var isLoadingAdvice = false
    @Published var errorMessage: String?

    // ✅ 新增：提供給 UI 顯示的今日關鍵字（最多 5 個由 repo 產生）
    @Published var todayKeywords: [String] = []

    private let repo: NewsRepository
    private let advice: AdviceClientProtocol

    init(repo: NewsRepository, advice: AdviceClientProtocol) {
        self.repo = repo
        self.advice = advice
    }

    func load(symbol: String) async {
        do {
            // 取近 7 天情緒（日分組）
            async let s7 = repo.dailySentiments(symbol: symbol, days: 7)
            let days7 = try await s7

            // 今日（最後一天）
            self.today = days7.last

            // 近 7 天聚合（平均與等級）
            func aggregate(_ arr: [SentimentDay]) -> (Double, String, [SentimentDay]) {
                let valid = arr.filter { $0.count > 0 }
                let avg = valid.isEmpty ? 0 : valid.map(\.score).reduce(0, +) / Double(valid.count)
                let level = avg > 0.2 ? "Optimistic" : (avg < -0.2 ? "Pessimistic" : "Neutral")
                return (avg, level, arr)
            }
            self.agg7 = aggregate(days7)

            // ✅ 把 Repository 算好的關鍵字丟給 UI
            self.todayKeywords = repo.lastKeywords

            // 預設用 RAG 打建議（用今天的分數與關鍵字）
            if let t = self.today {
                await loadAdvice(
                    symbol: symbol,
                    level: t.level,
                    score: t.score,
                    keywords: self.todayKeywords,   // ← 改用 vm.todayKeywords
                    mode: .rag
                )
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func loadAdvice(symbol: String, level: String, score: Double, keywords: [String], mode: AdviceMode) async {
        isLoadingAdvice = true
        defer { isLoadingAdvice = false }
        do {
            let tips = try await advice.fetchAdvice(
                mode: mode,
                symbol: symbol,
                level: level,
                keywords: keywords,
                score: score
            )
            self.adviceSuggestions = tips
        } catch is CancellationError {
            // 使用者離開畫面時的取消，不視為錯誤
        } catch {
            self.errorMessage = "Advice error: \(error.localizedDescription)"
            self.adviceSuggestions = []
        }
    }
}
