//
//  ResponseDataModelTest.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/3/5.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif

/// 這個 test case 測試 data model 是否正確對應到伺服器提供的 json
final class ResponseDataModelTest: XCTestCase {
    
    func testDecodeHistoricalRate() throws {
        // arrange
        let dateString = "1970-01-01"
        let historicalData = try XCTUnwrap(TestingData.historicalRateDataFor(dateString: dateString))
        
        // action
        let historicalRate = try ResponseDataModel.jsonDecoder
            .decode(ResponseDataModel.HistoricalRate.self,
                    from: historicalData)
        
        // assert
        XCTAssertEqual(historicalRate.dateString, dateString)
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    func testDecodeLatestRate() throws {
        // arrange
        let latestData = try XCTUnwrap(TestingData.latestData)

        // action
        let historicalRate = try ResponseDataModel.jsonDecoder
            .decode(ResponseDataModel.LatestRate.self,
                    from: latestData)
        
        // assert
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    func testEncodeAndThanDecode() throws {
        // arrange
        let dateString = "1970-01-01"
        let dummyHistoricalRate = try TestingData.historicalRateFor(dateString: dateString)
        
        // action
        let historicalRateData = try ResponseDataModel.jsonEncoder.encode(dummyHistoricalRate)
        let decodedHistoricalRate = try ResponseDataModel.jsonDecoder
            .decode(ResponseDataModel.HistoricalRate.self, from: historicalRateData)
        
        // assert
        XCTAssertEqual(dummyHistoricalRate, decodedHistoricalRate)
        XCTAssertEqual(dummyHistoricalRate.rates, decodedHistoricalRate.rates)
        XCTAssertEqual(dummyHistoricalRate.timestamp, decodedHistoricalRate.timestamp)
    }
}
