//
//  CombineCurrencyTests.swift
//  CombineCurrencyTests
//
//  Created by Pang-yen Chen on 2020/8/31.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import CombineCurrency
import Combine

class CombineCurrencyTests: XCTestCase {
    
    private var sut: RateListFetcher!
    
    private var anyCancellableSet = Set<AnyCancellable>()

    override func setUp() {
        sut = RateListFetcher(rateListSession: RateListSessionStub())
    }

    override func tearDown() {
        sut = nil
    }

    func testRateList() {
        
        let dummyEndpoint = RateListFetcher.Endpoint.latest
        
        sut.rateListPublisher(for: dummyEndpoint)
            .sink(
                receiveCompletion: { completion in
                    guard case .failure = completion else { return }
                    XCTFail()
                },
                receiveValue: { rateList in
                    assert(!(rateList.rates.isEmpty))
                }
            )
            .store(in: &anyCancellableSet)
    }
}

private class RateListSessionStub: RateListSession {
    func rateListDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        
        let urlResponse = HTTPURLResponse(url: URL(string: "https://www.apple.com/")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        
        
        return Just((data: RateList.data!, response: urlResponse!))
            .setFailureType(to: URLError.self)
            .eraseToAnyPublisher()
    }
}
