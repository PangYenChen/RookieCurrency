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
    
    private let timeoutTimeInterval: TimeInterval = 1
    
    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }
    
    override func tearDown() {
        sut = nil
        stubRateSession = nil
    }
    
    func testFetchLatestRate() throws {
        
        // arrange
        let expectation = expectation(description: "should get a latest rate instance")
        
        do {
            stubRateSession.data = TestingData.latestData
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
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
                case .success(let latestRate):
                    XCTAssertFalse(latestRate.rates.isEmpty)
                    
                    let dummyCurrencyCode = "TWD"
                    XCTAssertNotNil(latestRate[currencyCode: dummyCurrencyCode])
                    expectation.fulfill()
                case .failure:
                    XCTFail("should get a latest rate instance")
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testFetchHistoricalRate() throws {
        // arrange
        let expectation = expectation(description: "should get a historical rate instance")
        
        do {
            stubRateSession.data = TestingData.historicalData
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 200,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        let dummyDateString = "1970-01-01"
        
        // action
        sut
            .fetch(Endpoint.Historical(dateString: dummyDateString)) { result in
                // assert
                switch result {
                case .success(let rate):
                    XCTAssertFalse(rate.rates.isEmpty)
                    
                    let dummyCurrencyCode = "TWD"
                    XCTAssertNotNil(rate[currencyCode: dummyCurrencyCode])
                    
                    expectation.fulfill()
                case .failure:
                    XCTFail("should get a historical rate instance")
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testInvalidJSONData() throws {
        // arrange
        let expectation = expectation(description: "should fail to decode")
        let dummyEndpoint = Endpoint.Latest()
        do {
            stubRateSession.data = Data()
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 204,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // action
        sut
            .fetch(dummyEndpoint) { result in
                switch result {
                case .success:
                    XCTFail("should fail to decode")
                case .failure(let error):
                    if error is DecodingError {
                        expectation.fulfill()
                    } else {
                        XCTFail("get an error other than decoding error: \(error)")
                    }
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testTimeout() {
        // arrange
        let expectation = expectation(description: "should time out")
        let dummyEndpoint = Endpoint.Latest()
        do {
            stubRateSession.data = nil
            stubRateSession.response = nil
            stubRateSession.error = URLError(URLError.timedOut)
        }
        
        // action
        sut
            .fetch(dummyEndpoint) { result in
                // assert
                switch result {
                case .success:
                    XCTFail("should time out")
                case .failure(let error):
                    if let urlError = error as? URLError, urlError.code.rawValue == URLError.timedOut.rawValue  {
                        expectation.fulfill()
                    } else {
                        XCTFail("get an error other than timedOut: \(error)")
                    }
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testTooManyRequestRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        let expectation = expectation(description: "should receive a result")
        let dummyEndpoint = Endpoint.Latest()
        
        do {
            // first response
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 429,
                                           httpVersion: nil,
                                           headerFields: nil)

            spyRateSession.outputs.append((data: TestingData.tooManyRequestData, response: response, error: nil))
        }

        do {
            // second response
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)
            
            spyRateSession.outputs.append((data: TestingData.latestData, response: response, error: nil))
        }

        // action
        sut
            .fetch(dummyEndpoint) { result in
                // assert
                switch result {
                case .success:
                    XCTAssertEqual(Set(spyRateSession.receivedAPIKeys).count, 2)
                    expectation.fulfill()
                case .failure:
                    XCTFail("should not get any error")
                }
            }

        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testTooManyRequestFallBack() throws {
        // arrange
        let expectation = expectation(description: "should be unable to recover, pass error to call cite")
        let dummyEndpoint = Endpoint.Latest()
        do {
            stubRateSession.data = TestingData.tooManyRequestData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 429,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // action
        sut
            .fetch(dummyEndpoint) { result in
                // assert
                switch result {
                case .success:
                    XCTFail("should not receive any instance")
                case .failure(let error):
                    if let fetcherError = error as? Fetcher.Error, fetcherError == Fetcher.Error.tooManyRequest {
                        expectation.fulfill()
                    } else {
                        XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                    }
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testInvalidAPIKeyRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        let expectation = expectation(description: "should receive a dummy rate")
        let dummyEndpoint = Endpoint.Latest()
        
        do {
            // first response
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let httpURLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                statusCode: 401,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            spyRateSession.outputs.append((data: TestingData.invalidAPIKeyData, response: httpURLResponse, error: nil))
        }
        
        do {
            // second response
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let httpURLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                statusCode: 200,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            spyRateSession.outputs.append((data: TestingData.latestData, response: httpURLResponse, error: nil))
        }
        
        // action
        sut.fetch(dummyEndpoint) { result in
            // assert
            switch result {
            case .success:
                expectation.fulfill()
                XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
            case .failure:
                XCTFail("should not receive any error")
            }
        }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testInvalidAPIKeyFallBack() throws {
        // arrange
        let expectation = expectation(description: "should be unable to recover, pass error to call cite")
        let dummyEndpoint = Endpoint.Latest()
        do {
            stubRateSession.data = TestingData.tooManyRequestData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 401,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // action
        sut
            .fetch(dummyEndpoint) { result in
                // assert
                switch result {
                case .success:
                    XCTFail("should not receive any instance")
                case .failure(let error):
                    if let fetcherError = error as? Fetcher.Error, fetcherError == Fetcher.Error.invalidAPIKey {
                        expectation.fulfill()
                    } else {
                        XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                    }
                }
            }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testFetchSupportedSymbols() throws {
        // arrange
        let expectation = expectation(description: "should gat a list of supported symbols")
        
        do {
            stubRateSession.data = TestingData.supportedSymbols
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 200,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
            
        // action
        sut.fetch(Endpoint.SupportedSymbols()) { result in
            // assert
            switch result {
            case .success(let supportedSymbols):
                XCTAssertFalse(supportedSymbols.symbols.isEmpty)
                expectation.fulfill()
            case .failure(let failure):
                XCTFail("should not receive any failure, but receive: \(failure)")
            }
        }
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testTooManyRequestSimultaneously() throws {
        // arrange
        
        let spyAPIKeySession = SpyAPIKeyRateSession()
        sut = Fetcher(rateSession: spyAPIKeySession)
        let dummyEndpoint = Endpoint.Latest()
        
        // action
        sut.fetch(dummyEndpoint) { _ in }
        sut.fetch(dummyEndpoint) { _ in }
        
        do {
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil))
            
            if let firstFetcherCompletionHandler = spyAPIKeySession.completionHandlers.first {
                firstFetcherCompletionHandler(TestingData.tooManyRequestData, response, nil)
            } else {
                XCTFail("arrange 失誤，spy api key session 應該要收到來自 fetcher 的 completion handler")
            }
            
            if spyAPIKeySession.completionHandlers.count >= 2 {
                let secondFetcherCompletionHandler = spyAPIKeySession.completionHandlers[1]
                secondFetcherCompletionHandler(TestingData.tooManyRequestData, response, nil)
            } else  {
                XCTFail("arrange 失誤，spy api key session 應該要收到來自兩個 fetcher 的 completion handler")
            }
        }
        
        // assert
        if spyAPIKeySession.receivedAPIKeys.count == 4 {
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[0], spyAPIKeySession.receivedAPIKeys[1])
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[2], spyAPIKeySession.receivedAPIKeys[3])
        } else {
            XCTFail("spy api key session 應該要剛好收到 4 個 request")
        }
        
    }
}

// MARK: - test double
private final class StubRateSession: RateSession {
    
    var data: Data?
    
    var response: URLResponse?
    
    var error: Error?
    
    func rateDataTask(with request: URLRequest,
                      completionHandler: (Data?, URLResponse?, Error?) -> Void) {
        completionHandler(data, response, error)
    }
}

private final class SpyRateSession: RateSession {
    
    var outputs: [(data: Data?, response: URLResponse?, error: Error?)]
    
    private(set) var receivedAPIKeys: [String]
    
    init() {
        outputs = []
        receivedAPIKeys = []
    }
    
    func rateDataTask(with request: URLRequest,
                      completionHandler: (Data?, URLResponse?, Error?) -> Void) {
        
        if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
            receivedAPIKeys.append(receivedAPIKey)
        }
        
        guard !(outputs.isEmpty) else { return }
        
        let output = outputs.removeFirst()
        completionHandler(output.data, output.response, output.error)
    }
}

private final class SpyAPIKeyRateSession: RateSession {
    
    private(set) var completionHandlers: [(Data?, URLResponse?, Error?) -> Void]
    
    private(set) var receivedAPIKeys: [String]
    
    init() {
        completionHandlers = []
        receivedAPIKeys = []
    }
    
    func rateDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completionHandlers.append(completionHandler)
        if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
            receivedAPIKeys.append(receivedAPIKey)
        }
    }
}
