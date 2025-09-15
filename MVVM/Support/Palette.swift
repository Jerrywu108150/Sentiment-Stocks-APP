//
//  Palette.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/15.
//

import SwiftUI

// HEX 轉 Color 小工具
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 6: (r, g, b) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default: (r, g, b) = (0,0,0)
        }
        self = Color(.sRGB,
                     red: Double(r)/255.0,
                     green: Double(g)/255.0,
                     blue: Double(b)/255.0,
                     opacity: alpha)
    }
}

enum Palette {
    // 墨綠、深紅（可依喜好微調）
    static let deepGreen = Color(hex: "#0B3D2E")   // 墨綠
    static let forest    = Color(hex: "#115E4C")
    static let deepRed   = Color(hex: "#5B0006")   // 深紅
    static let maroon    = Color(hex: "#7A1020")

    static let cardBg    = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.25)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.75)
}

// 共用：整頁漸層背景
struct AppGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Palette.deepGreen, Palette.forest, Palette.maroon, Palette.deepRed],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// 共用：玻璃卡片（用於區塊容器）
struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(14)
            .background(Palette.cardBg, in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.cardStroke, lineWidth: 1))
    }
}

