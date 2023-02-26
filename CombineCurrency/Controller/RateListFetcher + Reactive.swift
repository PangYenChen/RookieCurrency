//
//  RateListFetcher + Reactive.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

extension RateListFetcher {
    func rateListPublisher(for endPoint: EndPoint) -> AnyPublisher<ResponseDataModel.RateList, Error> {
        
        func dataTaskPublisherWithLimitHandling(for endPoint: EndPoint) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            let urlRequest = createRequest(url: endPoint.url)
            
            return rateListSession.rateListDataTaskPublisher(for: urlRequest)
//                .receive(on: DispatchQueue.main)
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
