//
//  TickerListViewModel.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation

// MARK: - 首頁清單的 VM：提供搜尋與清單資料
@MainActor
final class TickerListViewModel: ObservableObject {
    @Published var search = ""
    @Published var items: [Ticker] = []          // Study: 顯示在畫面上的清單
    @Published var errorMessage: String?

    private var all: [Ticker] = []               // Study: 全部（做篩選來源）
    private var searchTask: Task<Void, Never>?
    private let repo: TickerRepository

    init(repo: TickerRepository = Dependencies.makeTickerRepository()) {
        self.repo = repo
    }

    // Study: App 首頁出現時呼叫，抓一次清單 → 存到 all → 顯示前 200 筆（避免首屏太重）
    func load() async {
        do {
            let fetched = try await repo.allUSTickers()
            self.all = fetched
            self.items = Array(fetched.prefix(200))
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // Study: 搜尋防抖（只在本地陣列 all 上過濾，不再打 API）
    func bindSearchDebounced() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            let q = self.search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if q.isEmpty {
                self.items = Array(self.all.prefix(200))
            } else {
                // symbol 或 name 命中就留下；限制回傳數量，避免列表太長
                self.items = self.all.lazy.filter {
                    $0.symbol.lowercased().contains(q) || $0.name.lowercased().contains(q)
                }.prefix(200)
                 .map { $0 }
            }
        }
    }
}
