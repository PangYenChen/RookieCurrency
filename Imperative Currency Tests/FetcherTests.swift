//
//  FetcherTests.swift
//  RookieCurrencyTests
//
//  Created by Pang-yen Chen on 2020/5/20.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import ImperativeCurrency

final class FetcherTests: XCTestCase {
    
    private var sut: Fetcher!
    
    private var stubRateSession: StubRateSession!
    
#warning("要拿掉time interval")
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
        var expectedLatestRateResult: Result<ResponseDataModel.LatestRate, Error>?
        
        do {
            stubRateSession.data = TestingData.latestData
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 200,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // act
        sut.fetch(Endpoints.Latest()) { result in expectedLatestRateResult = result }
        
        // assert
        switch expectedLatestRateResult {
        case .success(let latestRate):
            XCTAssertFalse(latestRate.rates.isEmpty)
            
            let dummyCurrencyCode = "TWD"
            XCTAssertNotNil(latestRate[currencyCode: dummyCurrencyCode])
        case .failure(let error):
            XCTFail("不應該發生錯誤，卻收到\(error)")
        case .none:
            XCTFail("expected latest rate result 不應該是 nil，可能是因為沒有成功把非同步的code轉成同步")
        }
        
    }
    
    func testFetchHistoricalRate() throws {
        // arrange
        let expectation = expectation(description: "should get a historical rate instance")
        
        let dummyDateString = "1970-01-01"
        
        do {
            stubRateSession.data = TestingData.historicalRateDataFor(dateString: dummyDateString)
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 200,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // act
        sut
            .fetch(Endpoints.Historical(dateString: dummyDateString)) { result in
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
        let dummyEndpoint = Endpoints.Latest()
        do {
            stubRateSession.data = Data()
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 204,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // act
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
        let dummyEndpoint = Endpoints.Latest()
        do {
            stubRateSession.data = nil
            stubRateSession.response = nil
            stubRateSession.error = URLError(URLError.timedOut)
        }
        
        // act
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
        let dummyEndpoint = Endpoints.Latest()
        
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

        // act
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
        let dummyEndpoint = Endpoints.Latest()
        do {
            stubRateSession.data = TestingData.tooManyRequestData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 429,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // act
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
        let dummyEndpoint = Endpoints.Latest()
        
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
        
        // act
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
        let dummyEndpoint = Endpoints.Latest()
        do {
            stubRateSession.data = TestingData.tooManyRequestData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            stubRateSession.response = HTTPURLResponse(url: url,
                                                       statusCode: 401,
                                                       httpVersion: nil,
                                                       headerFields: nil)
            stubRateSession.error = nil
        }
        
        // act
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
            
        // act
        sut.fetch(Endpoints.SupportedSymbols()) { result in
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
        let dummyEndpoint = Endpoints.Latest()
        let apiFinishingExpectation = expectation(description: "spy 應該收到 4 個 api key，前兩個一樣，後兩個一樣")
        apiFinishingExpectation.expectedFulfillmentCount = 2
        
        // act
        sut.fetch(dummyEndpoint) { _ in apiFinishingExpectation.fulfill()  }
        sut.fetch(dummyEndpoint) { _ in apiFinishingExpectation.fulfill()  }
        
        do {
            let data = TestingData.tooManyRequestData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil))
            
            if let firstFetcherCompletionHandler = spyAPIKeySession.completionHandlers.first {
                firstFetcherCompletionHandler(data, response, nil)
            } else {
                XCTFail("arrange 失誤，第一個 api call，fetcher 應該會 subscribe spy api key session，進而產生一個 subject")
            }
            
            if spyAPIKeySession.completionHandlers.count >= 2 {
                let secondFetcherCompletionHandler = spyAPIKeySession.completionHandlers[1]
                secondFetcherCompletionHandler(data, response, nil)
            } else  {
                XCTFail("arrange 失誤，第二個 api call，fetcher 應該會 subscribe spy api key session，進而產生二個 subject")
            }
        }
        
        do {
            let data     = try XCTUnwrap(TestingData.latestData)
            let url      = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = try XCTUnwrap(HTTPURLResponse(url : url, statusCode : 200, httpVersion : nil, headerFields : nil))
            
            if spyAPIKeySession.completionHandlers.count >= 3 {
                let thirdFetcherCompletionHandler = spyAPIKeySession.completionHandlers[2]
                thirdFetcherCompletionHandler(data, response, nil)
            } else  {
                XCTFail("arrange 失誤，第一個 api call，spy api key session 回傳 too many request 給 fetcher，fetcher 換完 api key 後會重新 subscribe spy api key session，這時後應該要產生第三個 subject。")
            }
            
            if spyAPIKeySession.completionHandlers.count >= 4 {
                let fourthFetcherCompletionHandler = spyAPIKeySession.completionHandlers[3]
                fourthFetcherCompletionHandler(data, response, nil)
            } else  {
                XCTFail("arrange 失誤，第二個 api call，spy api key session 回傳 too many request 給 fetcher，這次 fetcher 判斷不需換 api key，重新 subscribe spy api key session，這時後應該要產生第四個 subject。")
            }    
        }
        
        // assert
        if spyAPIKeySession.receivedAPIKeys.count == 4 {
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[0], spyAPIKeySession.receivedAPIKeys[1])
            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[2], spyAPIKeySession.receivedAPIKeys[3])
        } else {
            XCTFail("spy api key session 應該要剛好收到 4 個 request")
        }
        
        waitForExpectations(timeout: timeoutTimeInterval)
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
