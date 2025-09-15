//
//  HUD.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/15.
//

import SwiftUI

struct ThinkingHUD: View {
    let message: String
    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text(message)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(18)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(radius: 10)
        }
        .transition(.opacity)
    }
}
