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

final class ResponseDataModelTest: XCTestCase {
    
    func testDecodeHistoricalRate() throws {
        let jsonDecoder = ResponseDataModel.jsonDecoder
        let dateString = "2000-01-01"
        let historicalData = try XCTUnwrap(TestingData.historicalDataFor(dateString: dateString))
        let historicalRate = try jsonDecoder
            .decode(ResponseDataModel.HistoricalRate.self,
                    from: historicalData)
        XCTAssertEqual(historicalRate.dateString, dateString)
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    func testDecodeLatestRate() throws {
        let jsonDecoder = ResponseDataModel.jsonDecoder
        let latestData = try XCTUnwrap(TestingData.latestData)
        let historicalRate = try jsonDecoder
            .decode(ResponseDataModel.LatestRate.self,
                    from: latestData)
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    func testEncodeAndThanDecode() throws {
        let jsonEncoder = ResponseDataModel.jsonEncoder
        let dummyDateString = "1970-01-01"
        let dummyHistoricalRate = try TestingData.historicalRateFor(dateString: dummyDateString)
        let historicalRateData = try jsonEncoder.encode(dummyHistoricalRate)
        let decodedHistoricalRate = try JSONDecoder()
            .decode(ResponseDataModel.HistoricalRate.self, from: historicalRateData)
        XCTAssertEqual(dummyHistoricalRate, decodedHistoricalRate)
    }
}
