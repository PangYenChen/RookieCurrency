//
//  ArchiverTest.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/3/2.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest

#if RookieCurrency_Tests
@testable import RookieCurrency
#else
@testable import CombineCurrency
#endif

final class ArchiverTest: XCTestCase {
    
    let sut = Archiver.self
    
    func testArchiveAndThenUnarchive() throws {
        let dummyDateString = "1970-01-01"
        let dummyHistoricalRate = TestingData.historicalRate(dateString: dummyDateString)
        try sut.archive(historicalRate: dummyHistoricalRate)
        let unarchivedHistoricalRate = try sut.unarchive(historicalRateDateString: dummyHistoricalRate.dateString)
        
        XCTAssertEqual(dummyHistoricalRate, unarchivedHistoricalRate)
    }
}
