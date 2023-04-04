//
//  ImperativeRateControllerTests.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/4/3.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import RookieCurrency


final class ImperativeRateControllerTests: XCTestCase {
    
    let timeoutInterval: TimeInterval = 1
    
    var sut: RateController!
    
    override func tearDown() {
        sut = nil
    }
    
    func testNoCacheAndDiskData() {
        // arrange
        let stubFetcher = StubFetcher()
        SpyArchiver.reset()
        let spyArchiver = SpyArchiver.self
        sut = RateController(fetcher: stubFetcher, archiver: spyArchiver)
        
        let expectation = expectation(description: "should receive rate")
        let dummyStartingDate = Date(timeIntervalSince1970: 0)
        let numberOfDays = 3
        
        // action
        sut.getRateFor(numberOfDays: numberOfDays,
                       from: dummyStartingDate) { result in
            // assert
            switch result {
            case .success(let (_ , historicalRateSet)):
                XCTAssertEqual(historicalRateSet.count, numberOfDays)
                XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
                XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
                XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
                XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
                expectation.fulfill()
            case .failure(let failure):
                XCTFail("should not receive any failure but receive: \(failure)")
            }
        }
        
        waitForExpectations(timeout: timeoutInterval)
    }
    
    func testAllFromCache() {
        // arrange
        let stubFetcher = StubFetcher()
        SpyArchiver.reset()
        let spyArchiver = SpyArchiver.self
        sut = RateController(fetcher: stubFetcher, archiver: spyArchiver)
        
        let expectation = expectation(description: "should receive rate")
        let dummyStartingDate = Date(timeIntervalSince1970: 0)
        let numberOfDays = 3
        
        sut.getRateFor(numberOfDays: numberOfDays,
                       from: dummyStartingDate) { [unowned self] result in
            switch result {
            case .success(let (_ , historicalRateSet)):
                // first assert which may be not necessary
                XCTAssertEqual(historicalRateSet.count, numberOfDays)
                XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
                XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
                XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
                XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
                // action
                sut.getRateFor(numberOfDays: numberOfDays,
                               from: dummyStartingDate) { result in
                    switch result {
                    case .success(let (_ , historicalRateSet)):
                        // assert
                        XCTAssertEqual(historicalRateSet.count, numberOfDays)
                        XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
                        XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
                        XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 2)
                        XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
                        expectation.fulfill()
                    case .failure(let failure):
                        XCTFail("should not receive any failure but receive: \(failure)")
                    }
                }
            case .failure(let failure):
                XCTFail("should not receive any failure but receive: \(failure)")
            }
        }
        
        waitForExpectations(timeout: timeoutInterval)
    }
}

enum SpyArchiver: ArchiverProtocol {
    
    static private(set) var numberOfArchiveCall = 0
    
    static private(set) var numberOfUnarchiveCall = 0
    
    static private var archivedFileNames: [String] = []
    
    static func reset() {
        numberOfArchiveCall = 0
        numberOfUnarchiveCall = 0
        archivedFileNames = []
    }
    
    static func archive(historicalRate: RookieCurrency.ResponseDataModel.HistoricalRate) throws {
        numberOfArchiveCall += 1
        
        archivedFileNames.append(historicalRate.dateString)
    }
    

    static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
        numberOfUnarchiveCall += 1
        
        return TestingData.historicalRate(dateString: fileName)
    }
    
    static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool {
        archivedFileNames.contains(fileName)
    }
}

final class StubFetcher: FetcherProtocol {
    
    private(set) var numberOfLatestEndpointCall = 0
    
    private(set) var dateStringOfHistoricalEndpointCall: Set<String> = []
    
    func fetch<Endpoint>(_ endpoint: Endpoint, completionHandler: @escaping (Result<Endpoint.ResponseType, Error>) -> Void) where Endpoint : RookieCurrency.EndpointProtocol {
        
        if endpoint.url.path.contains("latest"),
           let latestRate = TestingData.latestRate as? Endpoint.ResponseType {
            numberOfLatestEndpointCall += 1
            
            completionHandler(.success(latestRate))
            return
            
        } else {
            let dateString = endpoint.url.lastPathComponent
            if AppUtility.requestDateFormatter.date(from: dateString) != nil,
               let historicalRate = TestingData.historicalRate(dateString: dateString) as? Endpoint.ResponseType {
                
                dateStringOfHistoricalEndpointCall.insert(dateString)
                
                completionHandler(.success(historicalRate))
                return
            }
        }
        
        completionHandler(.failure(Fetcher.Error.unknownError))
    }
}
