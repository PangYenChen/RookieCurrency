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
    
    private let timeoutTimeInterval: TimeInterval = 3
    
    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }
    
#warning("還要測 timeout、429")
    
    override func tearDown() {
        sut = nil
        stubRateSession = nil
    }
    
    func testFetchLatestRate() throws {
        
        // arrange
        let expectation = expectation(description: "should get a decoded latest rate instance")
        
        do {
            let data = TestingData.latestData
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)
            stubRateSession.outputs = [(data: data, response: response, error: nil)]
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
                    expectation.fulfill()
                case .failure:
                    XCTFail("should get a decoded latest rate instance")
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testFetchHistoricalRate() throws {
        // arrange
        let expectation = expectation(description: "should get a decoded historical rate instance")
        
        do {
            let data = TestingData.historicalData
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)
            stubRateSession.outputs = [(data: data, response: response, error: nil)]
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
                    
                    expectation.fulfill()
                case .failure:
                    XCTFail("should get a decoded historical rate instance")
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testDecodeFail() throws {
        // arrange
        let expectation = expectation(description: "should fail to decode")
        let dummyEndpoint = Endpoint.Latest()
        do {
            let data = Data()
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 204,
                                           httpVersion: nil,
                                           headerFields: nil)
            stubRateSession.outputs = [(data: data, response: response, error: nil)]
        }
        
        // action
        sut
            .fetch(dummyEndpoint) { result in
                switch result {
                case .success:
                    XCTFail("should fail to decode")
                case .failure(let failure):
                    if failure is DecodingError {
                        expectation.fulfill()
                    } else {
                        XCTFail("get an error other than decoding error: \(failure)")
                    }
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
}

private final class StubRateSession: RateSession {
    
    var outputs: [(data: Data?, response: URLResponse?, error: Error?)] = []
    
    func rateDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        guard !(outputs.isEmpty) else { return }
        
        let output = outputs.removeFirst()
        completionHandler(output.data, output.response, output.error)
    }
}
