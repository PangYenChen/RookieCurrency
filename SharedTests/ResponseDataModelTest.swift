//
//  ResponseDataModelTest.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/3/5.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest

#if RookieCurrency_Tests
@testable import RookieCurrency
#else
@testable import CombineCurrency
#endif

final class ResponseDataModelTest: XCTestCase {
    
    func testDecodeHistoricalRate() throws {
        let jsonDecoder = JSONDecoder()
        let historicalRate = try jsonDecoder
            .decode(ResponseDataModel.HistoricalRate.self,
                    from: TestingData.historicalData!)
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    func testDecodeLatestRate() throws {
        let jsonDecoder = JSONDecoder()
        let historicalRate = try jsonDecoder
            .decode(ResponseDataModel.LatestRate.self,
                    from: TestingData.latestData!)
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    func testEncodeAndThanDecode() throws {
        let dummyHistoricalRate = TestingData.historicalRate
        let historicalRateData = try JSONEncoder().encode(dummyHistoricalRate)
        let decodedHistoricalRate = try JSONDecoder()
            .decode(ResponseDataModel.HistoricalRate.self, from: historicalRateData)
        XCTAssertEqual(dummyHistoricalRate, decodedHistoricalRate)
    }
}
