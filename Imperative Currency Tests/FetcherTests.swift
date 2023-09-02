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
    
    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }
    
    override func tearDown() {
        sut = nil
        stubRateSession = nil
    }
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `LatestRate` instance
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
        do {
            let expectedLatestRateResult = try XCTUnwrap(expectedLatestRateResult)
            
            switch expectedLatestRateResult {
            case .success(let latestRate):
                XCTAssertFalse(latestRate.rates.isEmpty)
                
                let dummyCurrencyCode = "TWD"
                XCTAssertNotNil(latestRate[currencyCode: dummyCurrencyCode])
            case .failure(let error):
                XCTFail("不應該發生錯誤，卻收到\(error)")
            }
        }
    }
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `HistoricalRate` instance
    func testFetchHistoricalRate() throws {
        
        // arrange
        var expectedHistoricalRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        
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
        sut.fetch(Endpoints.Historical(dateString: dummyDateString)) { result in expectedHistoricalRateResult = result }
        
        // assert
        do {
            let expectedHistoricalRateResult = try XCTUnwrap(expectedHistoricalRateResult)
            
            switch expectedHistoricalRateResult {
            case .success(let historicalRate):
                XCTAssertFalse(historicalRate.rates.isEmpty)
                
                let dummyCurrencyCode = "TWD"
                XCTAssertNotNil(historicalRate[currencyCode: dummyCurrencyCode])
                
            case .failure(let error):
                XCTFail("不應該收到錯誤，卻收到\(error)")
            }
        }
    }
    
    /// 當 session 回傳無法 decode 的 json data 時，要能回傳 decoding error
    func testInvalidJSONData() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
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
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            
            case .success:
                XCTFail("should fail to decode")
            case .failure(let error):
                if !(error is DecodingError) {
                    XCTFail("get an error other than decoding error: \(error)")
                }
            }
        }
    }
    
    /// 當 session 回傳 timeout 時，fetcher 能確實回傳 timeout
    func testTimeout() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        
        do {
            stubRateSession.data = nil
            stubRateSession.response = nil
            stubRateSession.error = URLError(URLError.timedOut)
        }
        
        // act
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            switch expectedResult {
            case .success:
                XCTFail("should time out")
            case .failure(let error):
                guard let urlError = error as? URLError else {
                    XCTFail("應該要是 URLError，而不是其他 Error，例如 DecodingError。")
                    return
                }
                
                guard urlError.code.rawValue == URLError.timedOut.rawValue else {
                    XCTFail("get an error other than timedOut: \(error)")
                    return
                }
            }
        }
    }
    
    /// 當 session 回應正在使用的 api key 的額度用罄時，
    /// fetcher 能更換新的 api key 後重新 call session 的 method，
    /// 且新的 api key 尚有額度，session 正常回應。
    func testTooManyRequestRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
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
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success:
                XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
            case .failure:
                XCTFail("should not get any error")
            }
        }
    }
    
    /// session 回應正在使用的 api key 額度用罄，
    /// fetcher 更新 api key，
    /// 新的 api key 額度依舊用罄，
    /// fetcher 能回傳 api key 額度用罄的 error
    func testTooManyRequestFallBack() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
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
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success:
                XCTFail("should not receive any instance")
            case .failure(let error):
                guard let fetcherError = error as? Fetcher.Error else {
                    XCTFail("應該要收到 Fetcher.Error")
                    return
                }
                
                guard fetcherError == Fetcher.Error.tooManyRequest else {
                    XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                    return
                }
            }
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 新的 api key 有效， session 回應正常資料。
    func testInvalidAPIKeyRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)

        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
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
        sut.fetch(dummyEndpoint) { result in expectedResult = result
        }

        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success:
                XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
            case .failure:
                XCTFail("should not receive any error")
            }
        }
    }

    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 後續的 api key 全都無效，fetcher 能回傳 api key 無效的 error。
    func testInvalidAPIKeyFallBack() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.LatestRate, Error>?
        
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
        sut.fetch(dummyEndpoint) { result in expectedResult = result }
        
        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success:
                XCTFail("should not receive any instance")
            case .failure(let error):
                guard let fetcherError = error as? Fetcher.Error else {
                    XCTFail("should receive Fetcher.Error")
                    return
                }
                
                guard fetcherError == Fetcher.Error.invalidAPIKey else {
                    XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                    return
                }
            }
        }
    }
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `Symbols` instance
    func testFetchSupportedSymbols() throws {
        // arrange
        var expectedResult: Result<ResponseDataModel.Symbols, Error>?

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
        sut.fetch(Endpoints.SupportedSymbols()) { result in expectedResult = result }

        // assert
        do {
            let expectedResult = try XCTUnwrap(expectedResult)
            
            switch expectedResult {
            case .success(let supportedSymbols):
                XCTAssertFalse(supportedSymbols.symbols.isEmpty)
            case .failure(let failure):
                XCTFail("should not receive any failure, but receive: \(failure)")
            }
        }
        
    }
//
//    func testTooManyRequestSimultaneously() throws {
//        // arrange
//
//        let spyAPIKeySession = SpyAPIKeyRateSession()
//        sut = Fetcher(rateSession: spyAPIKeySession)
//        let dummyEndpoint = Endpoints.Latest()
//        let apiFinishingExpectation = expectation(description: "spy 應該收到 4 個 api key，前兩個一樣，後兩個一樣")
//        apiFinishingExpectation.expectedFulfillmentCount = 2
//
//        // act
//        sut.fetch(dummyEndpoint) { _ in apiFinishingExpectation.fulfill()  }
//        sut.fetch(dummyEndpoint) { _ in apiFinishingExpectation.fulfill()  }
//
//        do {
//            let data = TestingData.tooManyRequestData
//            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
//            let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil))
//
//            if let firstFetcherCompletionHandler = spyAPIKeySession.completionHandlers.first {
//                firstFetcherCompletionHandler(data, response, nil)
//            } else {
//                XCTFail("arrange 失誤，第一個 api call，fetcher 應該會 subscribe spy api key session，進而產生一個 subject")
//            }
//
//            if spyAPIKeySession.completionHandlers.count >= 2 {
//                let secondFetcherCompletionHandler = spyAPIKeySession.completionHandlers[1]
//                secondFetcherCompletionHandler(data, response, nil)
//            } else  {
//                XCTFail("arrange 失誤，第二個 api call，fetcher 應該會 subscribe spy api key session，進而產生二個 subject")
//            }
//        }
//
//        do {
//            let data     = try XCTUnwrap(TestingData.latestData)
//            let url      = try XCTUnwrap(URL(string: "https://www.apple.com"))
//            let response = try XCTUnwrap(HTTPURLResponse(url : url, statusCode : 200, httpVersion : nil, headerFields : nil))
//
//            if spyAPIKeySession.completionHandlers.count >= 3 {
//                let thirdFetcherCompletionHandler = spyAPIKeySession.completionHandlers[2]
//                thirdFetcherCompletionHandler(data, response, nil)
//            } else  {
//                XCTFail("arrange 失誤，第一個 api call，spy api key session 回傳 too many request 給 fetcher，fetcher 換完 api key 後會重新 subscribe spy api key session，這時後應該要產生第三個 subject。")
//            }
//
//            if spyAPIKeySession.completionHandlers.count >= 4 {
//                let fourthFetcherCompletionHandler = spyAPIKeySession.completionHandlers[3]
//                fourthFetcherCompletionHandler(data, response, nil)
//            } else  {
//                XCTFail("arrange 失誤，第二個 api call，spy api key session 回傳 too many request 給 fetcher，這次 fetcher 判斷不需換 api key，重新 subscribe spy api key session，這時後應該要產生第四個 subject。")
//            }
//        }
//
//        // assert
//        if spyAPIKeySession.receivedAPIKeys.count == 4 {
//            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[0], spyAPIKeySession.receivedAPIKeys[1])
//            XCTAssertEqual(spyAPIKeySession.receivedAPIKeys[2], spyAPIKeySession.receivedAPIKeys[3])
//        } else {
//            XCTFail("spy api key session 應該要剛好收到 4 個 request")
//        }
//
//        waitForExpectations(timeout: timeoutTimeInterval)
//    }
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
