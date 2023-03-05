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
    
    private var stubRateSession: StubRateSession!
    
    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }
    
#warning("還要測 timeout、429、decode error")
    
    override func tearDown() {
        sut = nil
        stubRateSession = nil
    }
    
    func testFetchLatestRate() throws {
        
        // arrange
        do {
            stubRateSession.data = TestingData.latestData
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.urlResponse = HTTPURLResponse(url: url,
                                                          statusCode: 200,
                                                          httpVersion: nil,
                                                          headerFields: nil)
            stubRateSession.error = nil
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
    
    func testFetchHistoricalRate() throws {
        
        // arrange
        do {
            stubRateSession.data = TestingData.historicalData
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.urlResponse = HTTPURLResponse(url: url,
                                                              statusCode: 200,
                                                              httpVersion: nil,
                                                              headerFields: nil)
            stubRateSession.error = nil
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

private class StubRateSession: RateSession {
    
    var data: Data?
    
    var urlResponse: URLResponse?
    
    var error: Error?
    
    func rateDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        completionHandler(TestingData.historicalData, nil, nil)
    }
}
