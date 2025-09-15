//
//  SentimentService.swift
//  SentimentStocks
//
//  Created by jerry wu on 2025/9/11.
//

import Foundation
import NaturalLanguage

// MARK: - 本地情緒分析（在地運算，不需伺服器）
// 使用 NLTagger 的 .sentimentScore，回傳約 -1...+1 的字串分數，轉 Double 再做平均。
protocol SentimentServiceProtocol {
    func score(headlines: [String]) -> Double
    func scoreFullTexts(texts: [String]) -> Double
    func topKeywords(from texts: [String], topK: Int) -> [String]
}

final class SentimentService: SentimentServiceProtocol {
    
    // 針對標題做情緒分析
    func score(headlines: [String]) -> Double {
        guard !headlines.isEmpty else { return 0 }
        let scores: [Double] = headlines.compactMap { headline in
            analyzeSentiment(for: headline)
        }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    // 針對完整新聞內文做情緒分析
    func scoreFullTexts(texts: [String]) -> Double {
        guard !texts.isEmpty else { return 0 }
        let scores: [Double] = texts.compactMap { text in
            analyzeSentiment(for: text)
        }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    // 抽取關鍵字 (當天新聞)
    func topKeywords(from texts: [String], topK: Int = 5) -> [String] {
        var freq: [String: Int] = [:]
        
        for text in texts {
            let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
            tagger.string = text
            let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
            
            tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                                 unit: .word,
                                 scheme: .lemma,
                                 options: options) { tag, tokenRange in
                if let lemma = tag?.rawValue.lowercased() {
                    // 過濾掉太短的詞、常見停用詞
                    guard lemma.count > 2, !stopWords.contains(lemma) else { return true }
                    freq[lemma, default: 0] += 1
                }
                return true
            }
        }
        
        return freq.sorted { $0.value > $1.value }
                   .prefix(topK)
                   .map { $0.key }
    }
    
    // MARK: - 私有工具
    
    private func analyzeSentiment(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        var scores: [Double] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .sentence,
                             scheme: .sentimentScore) { tag, _ in
            if let raw = tag?.rawValue, let val = Double(raw) {
                scores.append(val)
            }
            return true
        }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private let stopWords: Set<String> = [
        "the","and","for","with","that","from","this","have","will","are",
        "has","was","but","not","you","they","their","his","her","its",
        "our","can","all","more","one","two","three"
    ]
}
