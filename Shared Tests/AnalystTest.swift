//
//  AnalystTest.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/6/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest
#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif


final class AnalystTest: XCTestCase {
    
    /// 測試一切正常運作的 test method
    func testSimpleAnalyze() throws {
        // arrange
        
        // 使用的 currency of interest 就是強勢貨幣，但就這個 test method 的測試目的來說，只要 currency of interest 包含於測試資料中即可
        let currencyOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
        let historicalRate = try TestingData.historicalRateFor(dateString: "1970-01-01")
        let latestRate = try TestingData.latestRate()
        let baseCurrency = "USD"
        
        // act
        let analyzedData = Analyst.analyze(currencyOfInterest: currencyOfInterest,
                                           latestRate: latestRate,
                                           historicalRateSet: [historicalRate],
                                           baseCurrency: baseCurrency)
        
        // assert
        // 檢查回傳資料沒有遺漏
        XCTAssertEqual(Set(analyzedData.keys), currencyOfInterest)
        
        // 每個 currency 都成功分析
        let isAnalyzedDataContainsFailure = analyzedData.values
            .contains { result in
                switch result {
                case .success: return false
                case .failure: return true
                }
            }
        
        XCTAssertFalse(isAnalyzedDataContainsFailure)
        
        let analyzedResultRelativeToUSD = try XCTUnwrap(analyzedData["USD"])
        let analyzedDataRelativeToUSD = try analyzedResultRelativeToUSD.get()
        
        // 美金同時是 base currency 也是 currency of interest 時會有的性質
        XCTAssertEqual(analyzedDataRelativeToUSD.latest, 1)
        XCTAssertEqual(analyzedDataRelativeToUSD.mean, 1)
        XCTAssertEqual(analyzedDataRelativeToUSD.deviation, 0)
    }
}
