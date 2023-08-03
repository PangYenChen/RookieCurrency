//
//  RateControllerTests.swift
//
//  Created by 陳邦彥 on 2023/4/2.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif

/// 這個 test case 測試 rate controller 跟 fetcher 無關的 method
/// 即時間計算的 method
final class RateControllerTests: XCTestCase {
    
    var sut: RateController!
    
    var fakeFetcher: FakeFetcher!
    
    override func setUp() {
        fakeFetcher = FakeFetcher()
        sut = RateController(fetcher: fakeFetcher)
    }
    
    override func tearDown() {
        sut = nil
        fakeFetcher = nil
    }
    
    /// 測試 RateController.historicalRateDateStrings(numberOfDaysAgo:from:) method
    /// 模擬從執行當下的時間往前計算日期字串
    func testHistoricalRateDateStrings() throws {
        // arrange
        let startDay = Date(timeIntervalSince1970: 0)
        
        // act
        let historicalDateStrings = sut.historicalRateDateStrings(numberOfDaysAgo: 3, from: startDay)
        
        // assert
        XCTAssertEqual(historicalDateStrings, Set(["1969-12-31", "1969-12-30", "1969-12-29"]))
        XCTAssertEqual(fakeFetcher.numberOfMethodCall, 0)
    }
}
