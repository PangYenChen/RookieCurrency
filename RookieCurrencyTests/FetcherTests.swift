//
//  RookieCurrencyTests.swift
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
    
    func testLatest() {
#warning("要改名字")
        let dummyEndpoint = Fetcher.Endpoint.latest
        
        sut.rateList(for: dummyEndpoint) { result in
            switch result {
            case .success(let rateList):
                assert(!(rateList.rates.isEmpty))
            case .failure:
                XCTFail()
            }
        }
    }
    
    func testFetchLatest() {
        sut
            .fetch(Endpoint.Latest()) { result in
                switch result {
                case .success(let rateList):
                    XCTAssertFalse(rateList.rates.isEmpty)
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
        completionHandler(RateList.data, nil, nil)
    }
}
