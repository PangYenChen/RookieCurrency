//
//  RateControllerTests.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/4/2.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest

#if RookieCurrency_Tests
@testable import RookieCurrency
#else
@testable import CombineCurrency
import Combine
#endif

final class RateControllerTests: XCTestCase {
    
    var sut: RateController!
    
    var fakeFetcher: FakeFetcher!
    
    override func setUp() {
        fakeFetcher = FakeFetcher()
        sut = RateController(fetcher: fakeFetcher)
    }
    
    override func tearDown() {
        sut = nil
        fakeFetcher = nil
    }
    
    func testHistoricalRateDateString() throws {
        // arrange
        let startDay = Date(timeIntervalSince1970: 0)
        
        // action
        let historicalDateStrings = sut.historicalRateDateStrings(numberOfDaysAgo: 3, from: startDay)
        
        // assert
        XCTAssertEqual(historicalDateStrings, Set(["1969-12-31", "1969-12-30", "1969-12-29"]))
        XCTAssertEqual(fakeFetcher.numberOfMethodCall, 0)
    }
}

final class FakeFetcher: FetcherProtocol {
    
    private(set) var numberOfMethodCall = 0
    
    #if RookieCurrency_Tests
    
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
    ){
        // This is a fake instance, and any of it's method should not be called.
        
        numberOfMethodCall += 1
    }
    
    #else
    
    func publisher<Endpoint>(for endPoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Error> where Endpoint : CombineCurrency.EndpointProtocol {
        // This is a fake instance, and any of it's method should not be called.
        
        numberOfMethodCall += 1
        
        // the following code should be dead code
        return Empty().eraseToAnyPublisher()
    }
    
    #endif
}
