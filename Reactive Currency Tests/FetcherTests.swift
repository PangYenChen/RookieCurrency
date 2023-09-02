//
//  FetcherTests.swift
//  CombineCurrencyTests
//
//  Created by Pang-yen Chen on 2020/8/31.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import ReactiveCurrency
import Combine

class FetcherTests: XCTestCase {
    
    private var sut: Fetcher!
    
    private var stubRateSession: StubRateSession!
    
    private var anyCancellableSet = Set<AnyCancellable>()
    
    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }
    
    override func tearDown() {
        sut = nil
        stubRateSession = nil
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `LatestRate` instance
    func testPublishLatestRate() throws {
        
        // arrange
        var expectedValue: ResponseDataModel.LatestRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        do {
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            
            let httpURLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                statusCode: 200,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            
            let data = try XCTUnwrap(TestingData.latestData)
            
            stubRateSession.outputPublisher = Just((data: data, response: httpURLResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        
        // act
        sut.publisher(for: Endpoints.Latest())
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { latestRate in expectedValue = latestRate }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let dummyCurrencyCode = "TWD"
            let expectedLatestRate = try XCTUnwrap(expectedValue)
            XCTAssertNotNil(expectedLatestRate[currencyCode: dummyCurrencyCode])
            XCTAssertFalse(expectedLatestRate.rates.isEmpty)
        }
        
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            
            switch expectedCompletion {
            case .failure(let error):
                XCTFail("should not receive the .failure \(error)")
            case .finished:
                break
            }
        }
    }
    /// 測試 fetcher 可以在最正常的情況(status code 200，data 對應到 data model)下，回傳 `HistoricalRate` instance
    func testPublishHistoricalRate() throws {
        
        // arrange
        var expectedValue: ResponseDataModel.HistoricalRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        let dummyDateString = "1970-01-01"

        do {
            let data = try XCTUnwrap(TestingData.historicalRateDataFor(dateString: dummyDateString))
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            
            let httpURLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                statusCode: 200,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            
            stubRateSession.outputPublisher = Just((data: data, response: httpURLResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        
        // act
        sut.publisher(for: Endpoints.Historical(dateString: dummyDateString))
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { historicalRate in expectedValue = historicalRate }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            
            switch expectedCompletion {
            case .failure(let error):
                XCTFail("不應該收到錯誤，但收到\(error)")
            case .finished:
                break
            }
        }
        
        do {
            let expectedHistoricalRate = try XCTUnwrap(expectedValue)
            XCTAssertFalse(expectedHistoricalRate.rates.isEmpty)
            
            let dummyCurrencyCode = "TWD"
            XCTAssertNotNil(expectedHistoricalRate[currencyCode: dummyCurrencyCode])
        }
        
    }
    
    /// 當 session 回傳無法 decode 的 json data 時，要能回傳 decoding error
    func testInvalidJSONData() throws {
        // arrange
        var expectedValue: ResponseDataModel.LatestRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        
        do {
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let httpURLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                statusCode: 204,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            
            stubRateSession.outputPublisher = Just((data: Data(), response: httpURLResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { value in expectedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            switch expectedCompletion {
            case .failure(let error):
                if !(error is DecodingError) {
                    XCTFail("should not receive error other than decoding error: \(error)")
                }
            case .finished:
                XCTFail("should not complete normally")
            }
        }
        
        do {
            XCTAssertNil(expectedValue)
        }
    }
    
    /// 當 session 回傳 timeout 時，fetcher 能確實回傳 timeout
    func testTimeout() throws {
        // arrange
        var expectedValue: ResponseDataModel.LatestRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        do {
            stubRateSession.outputPublisher = Fail(error: URLError(URLError.timedOut))
                .eraseToAnyPublisher()
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { value in expectedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            switch expectedCompletion {
            case .failure(let error):
                guard let urlError = error as? URLError else {
                    XCTFail("應該要是 URLError，而不是其他 Error，例如 DecodingError。")
                    return
                }
                
                guard urlError.code.rawValue == URLError.timedOut.rawValue else {
                    XCTFail("get an error other than timedOut: \(error)")
                    return
                }
            case .finished:
                XCTFail("should not complete normally")
            }
        }
        
        do {
            XCTAssertNil(expectedValue)
        }
    }
    
    /// 當 session 回應正在使用的 api key 的額度用罄時，
    /// fetcher 能更換新的 api key 後重新 call session 的 method，
    /// 且新的 api key 尚有額度，session 正常回應。
    func testTooManyRequestRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        var expectedValue: ResponseDataModel.LatestRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        
        do {
            // first response
            let dummyData = try XCTUnwrap(TestingData.tooManyRequestData)
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let urlResponse: URLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                         statusCode: 429,
                                                                         httpVersion: nil,
                                                                         headerFields: nil))
            let outputPublisher = Just((data: dummyData, response: urlResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
            
            spyRateSession.outputPublishers.append(outputPublisher)
        }
        
        do {
            // second response
            let dummyData = try XCTUnwrap(TestingData.latestData)
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response: URLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                      statusCode: 200,
                                                                      httpVersion: nil,
                                                                      headerFields: nil))
            
            let outputPublisher = Just((data: dummyData, response: response))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
            
            spyRateSession.outputPublishers.append(outputPublisher)
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { value in expectedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            
            switch expectedCompletion {
            case .failure(let error):
                XCTFail("should not receive error: \(error)")
            case .finished:
                break
            }
        }
        
        do {
            XCTAssertNotNil(expectedValue)
            XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
        }
    }
    
    /// session 回應正在使用的 api key 額度用罄，
    /// fetcher 更新 api key，
    /// 新的 api key 額度依舊用罄，
    /// fetcher 能回傳 api key 額度用罄的 error
    func testTooManyRequestFallBack() throws {
        // arrange
        var expectedValue: ResponseDataModel.LatestRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint = Endpoints.Latest()
        do {
            let dummyData = try XCTUnwrap(TestingData.latestData)
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let httpURLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                statusCode: 429,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            
            stubRateSession.outputPublisher = Just((data: dummyData, response: httpURLResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        
        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { value in expectedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            switch expectedCompletion {
            case .failure(let error):
                guard let fetcherError = error as? Fetcher.Error else {
                    XCTFail("應該要收到 Fetcher.Error")
                    return
                }
                
                guard fetcherError == Fetcher.Error.tooManyRequest else {
                    XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                    return
                }
            case .finished:
                XCTFail("should not complete normally")
            }
        }
        
        do {
            XCTAssertNil(expectedValue)
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 新的 api key 有效， session 回應正常資料。
    func testInvalidAPIKeyRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)
        
        let dummyEndpoint = Endpoints.Latest()
        
        var expectedValue: ResponseDataModel.LatestRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        do {
            // first output
            let dummyData = try XCTUnwrap(TestingData.invalidAPIKeyData)
            let dummyURL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let httpURLResponse: URLResponse = try XCTUnwrap(HTTPURLResponse(url: dummyURL,
                                                                statusCode: 401,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            let outputPublisher = Just((data: dummyData, response: httpURLResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
            spyRateSession.outputPublishers.append(outputPublisher)
        }

        do {
            // second output
            let dummyData = try XCTUnwrap(TestingData.latestData)
            let dummyURL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let httpURLResponse: URLResponse = try XCTUnwrap(HTTPURLResponse(url: dummyURL,
                                                                             statusCode: 200,
                                                                             httpVersion: nil,
                                                                             headerFields: nil))
            let outputPublisher = Just((data: dummyData, response: httpURLResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
            spyRateSession.outputPublishers.append(outputPublisher)
        }

        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { value in expectedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            
            switch expectedCompletion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("should not receive any error:\(error)")
            }
        }
        
        do {
            XCTAssertNotNil(expectedValue)
            XCTAssertEqual(spyRateSession.receivedAPIKeys.count, 2)
        }
    }
    
    /// session 回應 api key 無效（可能是我在服務商平台更新某個 api key），
    /// fetcher 更換新的 api key 後再次 call session 的 method，
    /// 後續的 api key 全都無效，fetcher 能回傳 api key 無效的 error。
    func testInvalidAPIKeyFallBack() throws {
        // arrange
        var expectedValue: ResponseDataModel.LatestRate?
        var expectedCompletion: Subscribers.Completion<Error>?
        
        let dummyEndpoint = Endpoints.Latest()

        do {
            let dummyData = try XCTUnwrap(TestingData.invalidAPIKeyData)
            let dummyRUL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let httpURLResponse: URLResponse = try XCTUnwrap(HTTPURLResponse(url: dummyRUL,
                                                                statusCode: 401,
                                                                httpVersion: nil,
                                                                headerFields: nil))
            let outputPublish = Just((data: dummyData, response: httpURLResponse))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
            stubRateSession.outputPublisher = outputPublish
        }

        // act
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in expectedCompletion = completion },
                receiveValue: { value in expectedValue = value }
            )
            .store(in: &anyCancellableSet)
        
        // assert
        do {
            let expectedCompletion = try XCTUnwrap(expectedCompletion)
            
            switch expectedCompletion {
            case .failure(let error):
                guard let fetcherError = error as? Fetcher.Error else {
                    XCTFail("should receive Fetcher.Error")
                    return
                }
                
                guard fetcherError == Fetcher.Error.invalidAPIKey else {
                    XCTFail("receive error other than Fetcher.Error.tooManyRequest: \(error)")
                    return
                }
            case .finished:
                XCTFail("should not complete normally")
            }
        }
        
        do {
            XCTAssertNil(expectedValue)
        }

    }
//
//    func testFetchSupportedSymbols() throws {
//        // arrange
//        let outputExpectation = expectation(description: "should gat a list of supported symbols")
//        let finishedExpectation = expectation(description: "should finish normally")
//
//        do {
//            let data = try XCTUnwrap(TestingData.supportedSymbols)
//            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
//            let response = try XCTUnwrap(HTTPURLResponse(url: url,
//                                                         statusCode: 200,
//                                                         httpVersion: nil,
//                                                         headerFields: nil))
//            stubRateSession.outputPublisher = Just((data: data, response: response))
//                .setFailureType(to: URLError.self)
//                .eraseToAnyPublisher()
//        }
//
//        // act
//        sut.publisher(for: Endpoints.SupportedSymbols())
//            .sink(
//                // assert
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        finishedExpectation.fulfill()
//                    case .failure(let error):
//                        XCTFail("should not receive any error, but receive: \(error)")
//                    }
//                },
//                receiveValue: { supportedSymbol in
//                    XCTAssertFalse(supportedSymbol.symbols.isEmpty)
//                    outputExpectation.fulfill()
//                }
//            )
//            .store(in: &anyCancellableSet)
//
//        waitForExpectations(timeout: timeoutTimeInterval)
//    }
//
//    func testTooManyRequestSimultaneously() throws {
//        // arrange
//        let spyAPIKeySession = SpyAPIKeyRateSession()
//        sut = Fetcher(rateSession: spyAPIKeySession)
//        let dummyEndpoint = Endpoints.Latest()
//        let apiFinishingExpectation = expectation(description: "api 流程正常結束")
//        apiFinishingExpectation.expectedFulfillmentCount = 2
//        let apiOutputExpectation = expectation(description: "收到 fetcher 回傳的資料")
//        apiOutputExpectation.expectedFulfillmentCount = 2
//
//        // act
//        sut.publisher(for: dummyEndpoint)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished             : apiFinishingExpectation.fulfill()
//                    case .failure(let failure) : XCTFail("不應該收到錯誤卻收到\(failure)")
//                    }
//                },
//                receiveValue: { _ in apiOutputExpectation.fulfill() }
//            )
//            .store(in: &anyCancellableSet)
//
//        sut.publisher(for: dummyEndpoint)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished             : apiFinishingExpectation.fulfill()
//                    case .failure(let failure) : XCTFail("不應該收到錯誤卻收到\(failure)")
//                    }
//                },
//                receiveValue: { _ in apiOutputExpectation.fulfill() }
//            )
//            .store(in: &anyCancellableSet)
//
//
//        do {
//            let data     = try XCTUnwrap(TestingData.tooManyRequestData)
//            let url      = try XCTUnwrap(URL(string: "https://www.apple.com"))
//            let response = try XCTUnwrap(HTTPURLResponse(url : url, statusCode : 429, httpVersion : nil, headerFields : nil))
//
//            if let firstOutPutSubject = spyAPIKeySession.outputSubjects.first {
//                firstOutPutSubject.send((data, response))
//                firstOutPutSubject.send(completion: .finished)
//            } else {
//                XCTFail("arrange 失誤，第一個 api call，fetcher 應該會 subscribe spy api key session，進而產生一個 subject")
//            }
//
//            if spyAPIKeySession.outputSubjects.count >= 2 {
//                let secondOutPutSubject = spyAPIKeySession.outputSubjects[1]
//                secondOutPutSubject.send((data, response))
//                secondOutPutSubject.send(completion: .finished)
//            } else {
//                XCTFail("arrange 失誤，第二個 api call，fetcher 應該會 subscribe spy api key session，進而產生二個 subject")
//            }
//        }
//
//
//        do {
//            let data     = try XCTUnwrap(TestingData.latestData)
//            let url      = try XCTUnwrap(URL(string: "https://www.apple.com"))
//            let response = try XCTUnwrap(HTTPURLResponse(url : url, statusCode : 200, httpVersion : nil, headerFields : nil))
//
//            if spyAPIKeySession.outputSubjects.count >= 3 {
//                let thirdOutPutSubject = spyAPIKeySession.outputSubjects[2]
//                thirdOutPutSubject.send((data, response))
//                thirdOutPutSubject.send(completion: .finished)
//            } else {
//                XCTFail("arrange 失誤，第一個 api call，spy api key session 回傳 too many request 給 fetcher，fetcher 換完 api key 後會重新 subscribe spy api key session，這時後應該要產生第三個 subject。")
//            }
//
//            if spyAPIKeySession.outputSubjects.count >= 4 {
//                let fourthOutPutSubject = spyAPIKeySession.outputSubjects[3]
//                fourthOutPutSubject.send((data, response))
//                fourthOutPutSubject.send(completion: .finished)
//            } else {
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

private class StubRateSession: RateSession {
    
    var outputPublisher: AnyPublisher<(data: Data, response: URLResponse), URLError>!
    
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        outputPublisher
    }
}

private class SpyRateSession: RateSession {
    
    private(set) var receivedAPIKeys: [String]
    
    var outputPublishers: [AnyPublisher<(data: Data, response: URLResponse), URLError>]
    
    init() {
        receivedAPIKeys = []
        outputPublishers = []
    }
    
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        
        if let apikey = request.value(forHTTPHeaderField: "apikey") {
            receivedAPIKeys.append(apikey)
        }
        
        if outputPublishers.isEmpty {
            return Empty()
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        } else {
            return outputPublishers.removeFirst()
        }
    }
}


private final class SpyAPIKeyRateSession: RateSession {
    private(set) var receivedAPIKeys: [String]
    
    private(set) var outputSubjects: [PassthroughSubject<(data: Data, response: URLResponse), URLError>]
    
    init() {
        receivedAPIKeys = []
        outputSubjects = []
    }
    
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        if let receivedAPIKey = request.value(forHTTPHeaderField: "apikey") {
            receivedAPIKeys.append(receivedAPIKey)
        }
        
        let outputSubject = PassthroughSubject<(data: Data, response: URLResponse), URLError>()
        outputSubjects.append(outputSubject)
        
        return outputSubject.eraseToAnyPublisher()
    }
}
