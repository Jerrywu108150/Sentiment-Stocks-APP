//
//  AdviceStyles.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/15.
//

import SwiftUI

// 虛線膠囊標籤
struct DashedPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundStyle(Palette.textPrimary)
            .padding(.vertical, 6).padding(.horizontal, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .foregroundStyle(Palette.textPrimary.opacity(0.7))
            )
    }
}

// LLM 建議的每一則項目
struct AdviceRow: View {
    let index: Int
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index).")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 18, weight: .semibold, design: .monospaced)) // 機器感：等寬
                .foregroundStyle(Palette.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                        .foregroundStyle(Palette.textPrimary.opacity(0.5))
                )
        }
    }
}
