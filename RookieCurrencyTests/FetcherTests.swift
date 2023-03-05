//
//  FetcherTests.swift
//  RookieCurrencyTests
//
//  Created by Pang-yen Chen on 2020/5/20.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import RookieCurrency

final class FetcherTests: XCTestCase {
    
    private var sut: Fetcher!
    
    private var stubRateListSession: StubRateListSession!
    
    override func setUp() {
        stubRateListSession = StubRateListSession()
        sut = Fetcher(rateListSession: stubRateListSession)
    }
    
    #warning("還要測 timeout、429、decode error")
    
    override func tearDown() {
        sut = nil
        stubRateListSession = nil
    }
    
    func testFetchLatest() {
        
        // arrange
        do {
            stubRateListSession.data = TestingData.latestData
            stubRateListSession.urlResponse = nil
            stubRateListSession.error = nil
        }
        
        // action
        sut
            .fetch(Endpoint.Latest()) { result in
                // assert
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
        
        // arrange
        do {
            stubRateListSession.data = TestingData.historicalData
            stubRateListSession.urlResponse = nil
            stubRateListSession.error = nil
        }
        
        // action
        sut
            .fetch(Endpoint.Historical(date: .now)) { result in
                // assert
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

private class StubRateListSession: RateListSession {
    
    var data: Data?
    
    var urlResponse: URLResponse?
    
    var error: Error?
    
    func rateListDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        completionHandler(TestingData.historicalData, nil, nil)
    }
}
