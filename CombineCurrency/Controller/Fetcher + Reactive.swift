//
//  Fetcher + Reactive.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

// MARK: - RateListSession
protocol RateListSession {
    func rateListDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

// MARK: - make url session confirm RateListSession
extension URLSession: RateListSession {
    func rateListDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}

extension Fetcher {
    func rateListPublisher(for endPoint: Endpoint) -> AnyPublisher<ResponseDataModel.RateList, Error> {
        
        func dataTaskPublisherWithLimitHandling(for endPoint: Endpoint) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            let urlRequest = createRequest(url: endPoint.url)
            
            return rateListSession.rateListDataTaskPublisher(for: urlRequest)
                .flatMap { [unowned self] output -> AnyPublisher<(data: Data, response: URLResponse), URLError> in
                    
                    if shouldMakeNewAPICall(for: output.response) {
                        return dataTaskPublisherWithLimitHandling(for: endPoint)
                            .eraseToAnyPublisher()
                        
                    } else {
                        return Just((data: output.data, response: output.response))
                            .setFailureType(to: URLError.self)
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        }
        
        return dataTaskPublisherWithLimitHandling(for: endPoint)
            .map { $0.0 }
            .handleEvents(receiveOutput: prettyPrint)
            .decode(type: ResponseDataModel.RateList.self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
}