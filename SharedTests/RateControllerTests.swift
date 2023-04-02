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
    
    override func setUp() {
        sut = RateController(fetcher: FakeFetcher())
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testRequestDateString() {
        // arrange
        let startDay = Date(timeIntervalSince1970: 0)
        
        // action
        let historicalDateString = sut.requestDateStringForHistoricalRate(numberOfDaysAgo: 1, from: startDay)
        
        // assert
        XCTAssertEqual(historicalDateString, "1969-12-31")
    }
}

final class FakeFetcher: FetcherProtocol {
    #if RookieCurrency_Tests
    
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
    ){
        fatalError("This is a fake instance, and any of it's method should not be called.")
    }
    
    #else
    
    func publisher<Endpoint>(for endPoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Error> where Endpoint : CombineCurrency.EndpointProtocol {
        fatalError("This is a fake instance, and any of it's method should not be called.")
    }
    
    #endif
}
