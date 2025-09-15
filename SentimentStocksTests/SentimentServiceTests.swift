//
//  SentimentServiceTests.swift
//  SentimentStocksTests
//
//  Created by jerry wu on 2025/9/11.
//

import XCTest
@testable import SentimentStocks

final class SentimentServiceTests: XCTestCase {

    func testSentiment_PositiveHeadlines_ShouldBePositive() {
        let svc = SentimentService()
        let score = svc.score(headlines: [
            "beats expectations with strong guidance",
            "shares rally after upbeat report"
        ])
        XCTAssertGreaterThan(score, 0, "正向標題，平均分數應 > 0")
    }

    func testSentiment_NegativeHeadlines_ShouldBeNegative() {
        let svc = SentimentService()
        let score = svc.score(headlines: [
            "profit warning raises concerns",
            "regulatory issues weigh on outlook"
        ])
        XCTAssertLessThan(score, 0, "負向標題，平均分數應 < 0")
    }

    func testSentiment_Empty_ShouldBeZero() {
        let svc = SentimentService()
        XCTAssertEqual(svc.score(headlines: []), 0, accuracy: 1e-6)
    }
}
