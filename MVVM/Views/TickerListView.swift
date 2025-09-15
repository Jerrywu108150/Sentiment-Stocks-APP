//
//  TickerListView.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import SwiftUI


// MARK: - 首頁清單：搜尋＋點進個股
struct TickerListView: View {
    @StateObject var vm = TickerListViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // 用 Palette 定義的漸層背景
                AppGradientBackground()

                // 保持原本的 List + NavigationDestination 不變
                List(vm.items) { t in
                    NavigationLink(value: t.symbol) {
                        VStack(alignment: .leading) {
                            Text(t.symbol).font(.headline)
                            Text(t.name).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("cell_\(t.symbol)")
                }
                .navigationTitle("US Stocks")
                .searchable(text: $vm.search, prompt: "Symbol or Name")
                .onChange(of: vm.search) { _ in vm.bindSearchDebounced() }
                .task { await vm.load() }
                .navigationDestination(for: String.self) { sym in
                    StockDetailView(symbol: sym)
                }
            }
        }
    }
}

#Preview {
    TickerListView()
}
