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
        let dummyHistoricalRate = TestingData.historicalRate
        let dummyHistoricalRateSet: Set<ResponseDataModel.HistoricalRate> = [dummyHistoricalRate]
        try sut.archive(dummyHistoricalRateSet)
        let unarchivedHistoricalRateSet = try sut.unarchive()
        
        XCTAssertEqual(dummyHistoricalRateSet, unarchivedHistoricalRateSet)
    }
}
