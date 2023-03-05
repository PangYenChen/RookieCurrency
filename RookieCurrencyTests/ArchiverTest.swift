//
//  ArchiverTest.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/3/2.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import RookieCurrency

final class ArchiverTest: XCTestCase {
    
    let sut = Archiver.self
    
    func testArchiveAndThenUnarchive() throws {
        let dummyHistoricalRate = TestingData.historicalRate
        let dummyHistoricalRateSet: Set<ResponseDataModel.HistoricalRate> = [dummyHistoricalRate]
        try sut.archive(dummyHistoricalRateSet)
        let unarchivedHistoricalRateSet: Set<ResponseDataModel.HistoricalRate> = try sut.unarchive()
        
        XCTAssertEqual(dummyHistoricalRateSet, unarchivedHistoricalRateSet)
    }
}
