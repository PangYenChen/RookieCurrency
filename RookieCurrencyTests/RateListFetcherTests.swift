//
//  RookieCurrencyTests.swift
//  RookieCurrencyTests
//
//  Created by Pang-yen Chen on 2020/5/20.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import RookieCurrency

class RateListFetcherTests: XCTestCase {
    
    var sut: RateListFetcher!
    
    override func setUp() {
        sut = RateListFetcher(rateListSession: RateListSessionStub())
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testLatest() {
#warning("要改名字")
        let dummyEndpoint = RateListFetcher.EndPoint.latest
        
        sut.rateList(for: dummyEndpoint) { result in
            switch result {
            case .success(let rateList):
                assert(!(rateList.rates.isEmpty))
            case .failure:
                XCTFail()
            }
        }
    }
}

class RateListSessionStub: RateListSession {
    func rateListDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completionHandler(RateList.data, nil, nil)
    }
}
