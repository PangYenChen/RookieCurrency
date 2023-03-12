//
//  Fetcher + Reactive.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

// MARK: - RateSession
protocol RateSession {
    /// 把 URLSession 包一層起來，在測試的時候換掉。
    /// - Parameter request: The URL request for which to create a data task.
    /// - Returns: The publisher publishes data when the task completes, or terminates if the task fails with an error.
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

// MARK: - make url session confirm RateSession
extension URLSession: RateSession {
    func rateDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}

extension Fetcher {
    /// 像服務商的伺服器索取資料。
    /// - Parameter endPoint: The end point to be retrieved.
    /// - Returns: The publisher publishes decoded instance when the task completes, or terminates if the task fails with an error.
    func publisher<Endpoint: EndpointProtocol>(for endPoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Error> {
        
        func dataTaskPublisherWithLimitHandling(for endPoint: Endpoint) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            rateSession.rateDataTaskPublisher(for: createRequest(url: endPoint.url))
                .flatMap { [unowned self] data, response -> AnyPublisher<(data: Data, response: URLResponse), URLError> in
                    
                    if shouldMakeNewAPICall(for: response) {
                        return dataTaskPublisherWithLimitHandling(for: endPoint)
                            .eraseToAnyPublisher()
                        
                    } else {
                        return Just((data: data, response: response))
                            .setFailureType(to: URLError.self)
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        }
        
        return dataTaskPublisherWithLimitHandling(for: endPoint)
            .map { $0.0 }
            .handleEvents(receiveOutput: prettyPrint)
            .decode(type: Endpoint.ResponseType.self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
}
