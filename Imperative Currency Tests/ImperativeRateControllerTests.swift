//
//  ImperativeRateControllerTests.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/4/3.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import ImperativeCurrency


final class ImperativeRateControllerTests: XCTestCase {
#warning("要拿掉time interval")
    let timeoutInterval: TimeInterval = 1
    
    var sut: RateController!
    
    override func tearDown() {
        sut = nil
        TestDouble.SpyArchiver.reset()
    }
    
//    func testNoCacheAndDiskData() {
//        // arrange
//        let stubFetcher = StubFetcher()
//        let spyArchiver = TestDouble.SpyArchiver.self
//        sut = RateController(fetcher: stubFetcher, archiver: spyArchiver)
//        
//        let expectation = expectation(description: "should receive rate")
//        let dummyStartingDate = Date(timeIntervalSince1970: 0)
//        let numberOfDays = 3
//        
//        // act
//        sut.getRateFor(numberOfDays: numberOfDays,
//                       from: dummyStartingDate) { result in
//            // assert
//            switch result {
//            case .success(let (_ , historicalRateSet)):
//                XCTAssertEqual(historicalRateSet.count, numberOfDays)
//                XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//                XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//                XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
//                XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//                expectation.fulfill()
//            case .failure(let failure):
//                XCTFail("should not receive any failure but receive: \(failure)")
//            }
//        }
//        
//        waitForExpectations(timeout: timeoutInterval)
//    }
//    
//    func testAllFromCache() {
//        // arrange
//        let stubFetcher = StubFetcher()
//        let spyArchiver = TestDouble.SpyArchiver.self
//        sut = RateController(fetcher: stubFetcher, archiver: spyArchiver)
//        
//        let expectation = expectation(description: "should receive rate")
//        let dummyStartingDate = Date(timeIntervalSince1970: 0)
//        let numberOfDays = 3
//        
//        sut.getRateFor(numberOfDays: numberOfDays,
//                       from: dummyStartingDate) { [unowned self] result in
//            switch result {
//            case .success(let (_ , historicalRateSet)):
//                // first assert which may be not necessary
//                XCTAssertEqual(historicalRateSet.count, numberOfDays)
//                XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//                XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//                XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
//                XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//                // act
//                sut.getRateFor(numberOfDays: numberOfDays,
//                               from: dummyStartingDate) { result in
//                    switch result {
//                    case .success(let (_ , historicalRateSet)):
//                        // assert
//                        XCTAssertEqual(historicalRateSet.count, numberOfDays)
//                        XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//                        XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//                        XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 2)
//                        XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//                        expectation.fulfill()
//                    case .failure(let failure):
//                        XCTFail("should not receive any failure but receive: \(failure)")
//                    }
//                }
//            case .failure(let failure):
//                XCTFail("should not receive any failure but receive: \(failure)")
//            }
//        }
//        
//        waitForExpectations(timeout: timeoutInterval)
//    }
}

final class StubFetcher: FetcherProtocol {
    
    private(set) var numberOfLatestEndpointCall = 0
    
    private(set) var dateStringOfHistoricalEndpointCall: Set<String> = []
    
    func fetch<Endpoint>(_ endpoint: Endpoint, completionHandler: @escaping (Result<Endpoint.ResponseType, Error>) -> Void) where Endpoint : ImperativeCurrency.EndpointProtocol {
        
        if endpoint.url.path.contains("latest"),
           let latestRate = TestingData.Instance.latestRate as? Endpoint.ResponseType {
            numberOfLatestEndpointCall += 1
            
            completionHandler(.success(latestRate))
            return
            
        } else {
            let dateString = endpoint.url.lastPathComponent
            do {
                if AppUtility.requestDateFormatter.date(from: dateString) != nil,
                   let historicalRate = try TestingData.Instance.historicalRateFor(dateString: dateString) as? Endpoint.ResponseType {
                    
                    dateStringOfHistoricalEndpointCall.insert(dateString)
                    
                    completionHandler(.success(historicalRate))
                    return
                    
#warning("這邊邏輯要檢查一下")
                }
            } catch {
                completionHandler(.failure(error))
                
            }
        }
        
        // the following should be dead code, which purely make compiler silent
        completionHandler(.failure(Fetcher.Error.unknownError))
    }
}
