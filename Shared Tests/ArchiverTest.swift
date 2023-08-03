//
//  ArchiverTest.swift
//
//  Created by 陳邦彥 on 2023/3/2.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif

/// 測試 archiver 的 test case
/// 我不太確定要怎麼測試，archiver 其實很薄。
final class ArchiverTest: XCTestCase {
    
    let sut = Archiver.self
    
    /// 測試先存一個檔案，再讀出來，確認前後一致。
    /// 我知道這樣不好，應該要抽換掉 `Data` 之類的 dependency，
    /// 但是把 `Data` 包一層又怪怪的。
    func testArchiveAndThenUnarchive() throws {
        // arrange
        let dummyDateString = "1970-01-01"
        let dummyHistoricalRate = try TestingData.historicalRateFor(dateString: dummyDateString)
        
        // act
        try sut.archive(historicalRate: dummyHistoricalRate)
        let unarchivedHistoricalRate = try sut.unarchive(historicalRateDateString: dummyHistoricalRate.dateString)
        
        // assert
        XCTAssertEqual(dummyHistoricalRate, unarchivedHistoricalRate)
    }
}
