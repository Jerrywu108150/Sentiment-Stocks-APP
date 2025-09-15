//
//  StockDetailView.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import SwiftUI



struct StockDetailView: View {
    let symbol: String
    @StateObject private var vm: StockDetailViewModel
    @State private var useRAG = true
    @State private var showThinkingHUD = true   // 進場先顯示

    init(symbol: String) {
        self.symbol = symbol
        _vm = StateObject(wrappedValue:
            StockDetailViewModel(
                repo: Dependencies.makeRepository(),
                advice: Dependencies.makeAdviceClient()
            )
        )
    }

    var body: some View {
        ZStack {
            AppGradientBackground()  // 漸層背景

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // 頂部標題列
                    HStack(alignment: .firstTextBaseline) {
                        Text(symbol)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer(minLength: 8)
                        Toggle("RAG", isOn: $useRAG)
                            .labelsHidden()
                            .tint(.teal)
                    }
                    .padding(.top, 8)

                    // 今日分數 + 情緒
                    if let t = vm.today {
                        GlassCard {
                            HStack(spacing: 12) {
                                Text("Today")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Palette.textSecondary)
                                Text("\(t.score, specifier: "%.2f")")
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Palette.textPrimary)

                                DashedPill(text: t.level)
                                    .foregroundStyle(
                                        t.level == "Optimistic" ? Color.blue :
                                        t.level == "Neutral" ? Color.gray :
                                        t.level == "Pessimistic" ? Color.orange :
                                        Color.primary
                                    )

                                Spacer()
                                Text("\(t.count) articles")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                    }

                    // 近 7 天聚合
                    if let a = vm.agg7 {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Last 7 days")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Palette.textPrimary)
                                HStack(spacing: 10) {
                                    Text("Avg: \(a.avg, specifier: "%.2f")")
                                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Palette.textPrimary)
                                    DashedPill(text: a.level)
                                        .foregroundStyle(
                                            a.level == "Optimistic" ? Color.blue :
                                            a.level == "Neutral" ? Color.gray :
                                            a.level == "Pessimistic" ? Color.orange :
                                            Color.primary
                                        )
                                }
                            }
                        }
                    }

                    // --- 今日關鍵字（最多 5 個）---
                    if !vm.todayKeywords.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Today’s Keywords")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Palette.textPrimary)

                                let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
                                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                                    ForEach(vm.todayKeywords.prefix(5), id: \.self) { kw in
                                        DashedPill(text: kw)
                                            .accessibilityIdentifier("kw_\(kw)")
                                    }
                                }
                            }
                        }
                    }


                    // 建議區塊
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Today’s Advice")
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Palette.textPrimary)
                                Spacer()
                                if vm.isLoadingAdvice {
                                    ProgressView().tint(.white)
                                }
                            }

                            if vm.adviceSuggestions.isEmpty {
                                Text("No suggestions yet.")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Palette.textSecondary)
                            } else {
                                ForEach(Array(vm.adviceSuggestions.enumerated()), id: \.offset) { i, s in
                                    AdviceRow(index: i+1, text: s)
                                }
                            }

                            Button {
                                Task {
                                    guard let t = vm.today else { return }
                                    showThinkingHUD = true
                                    await vm.loadAdvice(
                                        symbol: symbol,
                                        level: t.level,
                                        score: t.score,
                                        keywords: vm.todayKeywords,         // ← 傳入今日關鍵字
                                        mode: useRAG ? .rag : .noRag
                                    )
                                    showThinkingHUD = false
                                }
                            } label: {
                                Text("Refresh Advice")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 10).padding(.horizontal, 14)
                                    .background(.blue.opacity(0.6), in: .rect(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 6)
                        }
                    }

                    if let e = vm.errorMessage {
                        Text(e)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.red.opacity(0.9))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            // 進場與重整時的 HUD
            if showThinkingHUD {
                ThinkingHUD(message: vm.isLoadingAdvice ? "AI is computing advices…" : "Sentiment analyzing…")
            }
        }
        .task {
            showThinkingHUD = true
            await vm.load(symbol: symbol)
            showThinkingHUD = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar) // 讓背景漸層自然延伸
    }
}

#Preview {
    StockDetailView(symbol: "GOOGL")
}
