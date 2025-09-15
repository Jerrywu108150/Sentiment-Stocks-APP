//
//  TickerRow.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/15.
//

import SwiftUI

struct TickerRow: View {
    let symbol: String
    let name: String

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                // 簡單縮寫徽章（機器感等寬字）
                Text(symbol)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.vertical, 6).padding(.horizontal, 10)
                    .background(.white.opacity(0.08), in: .rect(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.25), lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.textPrimary)

                    Text("Tap to view sentiment & advice")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.textSecondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        // 讓整列點擊區域更大
        .contentShape(Rectangle())
    }
}
