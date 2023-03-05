//
//  FetcherTests.swift
//  RookieCurrencyTests
//
//  Created by Pang-yen Chen on 2020/5/20.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import RookieCurrency

class FetcherTests: XCTestCase {
    
    var sut: Fetcher!
    
    override func setUp() {
        sut = Fetcher(rateListSession: RateListSessionStub())
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testFetchLatest() {
        sut
            .fetch(Endpoint.Latest()) { result in
                switch result {
                case .success(let rate):
                    XCTAssertFalse(rate.rates.isEmpty)
                    
                    let dummyCurrency = Currency.TWD
                    XCTAssertNotNil(rate[dummyCurrency])
                case .failure:
                    XCTFail()
                }
            }
    }
    
    func testFetchHistorical() {
        sut
            .fetch(Endpoint.Historical(date: .now)) { result in
                switch result {
                case .success(let rate):
                    XCTAssertFalse(rate.rates.isEmpty)
                    
                    let dummyCurrency = Currency.TWD
                    XCTAssertNotNil(rate[dummyCurrency])
                case .failure:
                    XCTFail()
                }
            }
    }
}

private class RateListSessionStub: RateListSession {
    func rateListDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        completionHandler(TestingData.historicalData, nil, nil)
    }
}
