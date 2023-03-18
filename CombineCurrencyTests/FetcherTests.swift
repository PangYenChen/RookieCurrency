//
//  FetcherTests.swift
//  CombineCurrencyTests
//
//  Created by Pang-yen Chen on 2020/8/31.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import CombineCurrency
import Combine

class FetcherTests: XCTestCase {
    
    private var sut: Fetcher!
    
    private var stubRateSession: StubRateSession!
    
    private let timeoutTimeInterval: TimeInterval = 1
    
    private var anyCancellableSet = Set<AnyCancellable>()

    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }

    override func tearDown() {
        sut = nil
        stubRateSession = nil
    }
#warning("還要測429")
    
    func testPublishLatestRate() throws {
        
        // arrange
        let valueExpectation = expectation(description: "should gate a latest rate instance")
        let finishedExpectation = expectation(description: "should receive .finished")
        
        do {
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            
            let httpURLResponse = HTTPURLResponse(url: url,
                                                  statusCode: 200,
                                                  httpVersion: nil,
                                                  headerFields: nil)
            
            let urlResponse = try XCTUnwrap(httpURLResponse.map { $0 as URLResponse })
            
            let data = try XCTUnwrap(TestingData.latestData)
            
            stubRateSession.result = .success((data: data, response: urlResponse))
        }
        
        // action
        sut.publisher(for: Endpoint.Latest())
            .sink(
                // assert
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        finishedExpectation.fulfill()
                    case .failure(let error):
                        XCTFail("should not receive the .failure \(error)")
                    }
                },
                receiveValue: { latestRate in
                    let dummyCurrency = Currency.TWD
                    XCTAssertNotNil(latestRate[dummyCurrency])
                    
                    XCTAssertFalse(latestRate.rates.isEmpty)
                    valueExpectation.fulfill()
                }
            )
            .store(in: &anyCancellableSet)
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testPublishHistoricalRate() throws {
        
        // arrange
        let valueExpectation = expectation(description: "should receive a historical rate")
        let finishedExpectation = expectation(description: "should receive a .finished")
        
        do {
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            
            let httpURLResponse = HTTPURLResponse(url: url,
                                                  statusCode: 200,
                                                  httpVersion: nil,
                                                  headerFields: nil)
            
            let urlResponse = try XCTUnwrap(httpURLResponse)
            
            let data = try XCTUnwrap(TestingData.historicalData)
            
            stubRateSession.result = .success((data: data, response: urlResponse))
        }
        
        // action
        sut.publisher(for: Endpoint.Historical(date: .now))
            .sink(
                // assert
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        XCTFail("should not receive the .failure \(error)")
                    case .finished:
                        finishedExpectation.fulfill()
                    }
                },
                receiveValue: { historicalRate in
                    XCTAssertFalse(historicalRate.rates.isEmpty)
                    
                    let dummyCurrency = Currency.TWD
                    XCTAssertNotNil(historicalRate[dummyCurrency])
                    
                    valueExpectation.fulfill()
                }
            )
            .store(in: &anyCancellableSet)
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testInvalidJSONData() throws {
        // arrange
        let expectation = expectation(description: "should fail to decode")
        let dummyEndpoint = Endpoint.Latest()
        
        do {
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = try XCTUnwrap(HTTPURLResponse(url: url,
                                                         statusCode: 204,
                                                         httpVersion: nil,
                                                         headerFields: nil))
            
            stubRateSession.result = .success((data: Data(), response: response))
        }
        
        // action
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                // assert
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        if error is DecodingError {
                            expectation.fulfill()
                        } else {
                            XCTFail("should not receive error other than decoding error: \(error)")
                        }
                    case .finished:
                        XCTFail("should not complete normally")
                    }
                },
                receiveValue: { value in
                    XCTFail("should not receive value: \(value)")
                }
            )
            .store(in: &anyCancellableSet)
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testTimeout() {
        // arrange
        let expectation = expectation(description: "should time out")
        let dummyEndpoint = Endpoint.Latest()
        do {
            stubRateSession.result = .failure(URLError(URLError.timedOut))
        }
        
        // action
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                // assert
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        if let urlError = error as? URLError, urlError.code.rawValue == URLError.timedOut.rawValue {
                            expectation.fulfill()
                        } else {
                            XCTFail("should not receive error other than timeout: \(error)")
                        }
                    case .finished:
                        XCTFail("should not complete normally")
                    }
                },
                receiveValue: { value in
                    XCTFail("should not receive value: \(value)")
                }
            )
            .store(in: &anyCancellableSet)
        
        waitForExpectations(timeout: timeoutTimeInterval)
    }
    
    func testTooManyRequestRecovery() throws {
        // arrange
        let spyRateSession = SpyRateSession()
        sut = Fetcher(rateSession: spyRateSession)

        let valueExpectation = expectation(description: "should receive a result")
        let finishedExpectation = expectation(description: "should complete normally")
        let dummyEndpoint = Endpoint.Latest()

        do {
            // first response
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response: URLResponse = try XCTUnwrap(HTTPURLResponse(url: url,
                                                                      statusCode: 429,
                                                                      httpVersion: nil,
                                                                      headerFields: nil))
            let outputPublisher = Just((data: Data(), response: response))
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

        // action
        sut
            .publisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        XCTFail("should not receive error: \(error)")
                    case .finished:
                        finishedExpectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTAssertEqual(Set(spyRateSession.receivedAPIKeys).count, 2)
                    valueExpectation.fulfill()
                }
            )
            .store(in: &anyCancellableSet)

        waitForExpectations(timeout: timeoutTimeInterval)
    }

}

private class StubRateSession: RateSession {
    
    var result: Result<(data: Data, response: URLResponse), URLError>!
    
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        result
            .publisher
            .eraseToAnyPublisher()
    }
}

private class SpyRateSession: RateSession {
    
    private(set) var receivedAPIKeys = [String]()
    
    var outputPublishers = [AnyPublisher<(data: Data, response: URLResponse), URLError>]()
    
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        
        if let apikey = request.value(forHTTPHeaderField: "apikey") {
            receivedAPIKeys.append(apikey)
        }
        
        if outputPublishers.isEmpty {
            return Empty(completeImmediately: true)
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        } else {
            return outputPublishers.removeFirst()
        }
    }
}
