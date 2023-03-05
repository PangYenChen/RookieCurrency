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
    
    private var anyCancellableSet = Set<AnyCancellable>()

    override func setUp() {
        stubRateSession = StubRateSession()
        sut = Fetcher(rateSession: stubRateSession)
    }

    override func tearDown() {
        sut = nil
        stubRateSession = nil
    }
#warning("還要測 timeout、429、decode error")
    
    func testPublishLatestRate() throws {
        
        // arrange
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
                    guard case .failure = completion else { return }
                    XCTFail()
                },
                receiveValue: { latestRate in
                    XCTAssertFalse(latestRate.rates.isEmpty)
                }
            )
            .store(in: &anyCancellableSet)
    }
    
    func testPublishHistoricalRate() throws {
        
        // arrange
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
                    guard case .failure = completion else { return }
                    XCTFail()
                },
                receiveValue: { historicalRate in
                    XCTAssertFalse(historicalRate.rates.isEmpty)
                }
            )
            .store(in: &anyCancellableSet)
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
