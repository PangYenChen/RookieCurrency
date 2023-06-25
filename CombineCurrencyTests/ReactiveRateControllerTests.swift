//
//  ReactiveRateControllerTests.swift
//  CombineCurrencyTests
//
//  Created by 陳邦彥 on 2023/4/9.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest
import Combine
@testable import CombineCurrency

final class ReactiveRateControllerTests: XCTestCase {
    let timeoutInterval: TimeInterval = 1
    
    var sut: RateController!
    
    var anyCancellableSet: Set<AnyCancellable> = []
    
    override func tearDown() {
        sut = nil
        TestDouble.SpyArchiver.reset()
    }
    
    func testtestNoCacheAndDiskData() {
        // arrange
        let stubFetcher = StubFetcher()
        let spyArchiver = TestDouble.SpyArchiver.self
        sut = RateController(fetcher: stubFetcher, archiver: spyArchiver)
        
        let valueExpectation = expectation(description: "should receive rate")
        let finishedExpectation = expectation(description: "should finish normally")
        let dummyStartingDate = Date(timeIntervalSince1970: 0)
        let numberOfDays = 3
        
        // action
        sut
            .ratePublisher(numberOfDay: numberOfDays, from: dummyStartingDate)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        finishedExpectation.fulfill()
                    case .failure(let error):
                        XCTFail("should not receive any failure but receive: \(error)")
                    }
                },
                receiveValue: { (_, historicalRateSet) in
                    XCTAssertEqual(historicalRateSet.count, numberOfDays)
                    XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
                    XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
                    XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
                    XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
                    valueExpectation.fulfill()
                }
            )
            .store(in: &anyCancellableSet)
        
        waitForExpectations(timeout: timeoutInterval)
    }
    
    func testAllFromCache() {
        // arrange
        let stubFetcher = StubFetcher()
        let spyArchiver = TestDouble.SpyArchiver.self
        sut = RateController(fetcher: stubFetcher, archiver: spyArchiver)
        
        let outputExpectation = expectation(description: "should receive rate")
        let finishedExpectation = expectation(description: "should finish normally")
        let dummyStartingDate = Date(timeIntervalSince1970: 0)
        let numberOfDays = 3
        
        sut.ratePublisher(numberOfDay: numberOfDays, from: dummyStartingDate)
            .flatMap { [unowned self] _ in sut.ratePublisher(numberOfDay: numberOfDays, from: dummyStartingDate) }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        finishedExpectation.fulfill()
                    case .failure(let error):
                        XCTFail("should not receive any failure but receive: \(error)")
                    }
                },
                receiveValue: { (_, historicalRateSet) in
                    XCTAssertEqual(historicalRateSet.count, numberOfDays)
                    XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
                    XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
                    XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 2)
                    XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
                    outputExpectation.fulfill()
                }
            )
            .store(in: &anyCancellableSet)

        waitForExpectations(timeout: timeoutInterval)
    }
}

final class StubFetcher: FetcherProtocol {
    
    private(set) var numberOfLatestEndpointCall = 0
    
    private(set) var dateStringOfHistoricalEndpointCall: Set<String> = []
    
    func publisher<Endpoint>(for endpoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Error> where Endpoint : EndpointProtocol {
        if endpoint.url.path.contains("latest"),
           let latestRate = TestingData.latestRate as? Endpoint.ResponseType {
            numberOfLatestEndpointCall += 1
            
            return Just(latestRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            let dateString = endpoint.url.lastPathComponent
            if AppUtility.requestDateFormatter.date(from: dateString) != nil,
               let historicalRate = TestingData.historicalRate(dateString: dateString) as? Endpoint.ResponseType {
                
                dateStringOfHistoricalEndpointCall.insert(dateString)
                
                return Just(historicalRate)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }
        
        // the following should be dead code, which purely make compiler silent
        return Fail(error: Fetcher.Error.unknownError)
            .eraseToAnyPublisher()
    }
}
