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
            
            return  rookieURLSession.rookieDataTaskPublisher(for: urlRequest)
                .receive(on: DispatchQueue.main)
                .flatMap { [unowned self] output -> AnyPublisher<(data: Data, response: URLResponse), URLError> in
                    if let httpURLResponse = output.response as? HTTPURLResponse,
                       httpURLResponse.statusCode == 429,
                       updateAPIKeySuccess() {
                        
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
            .tryMap { [unowned self] data -> Data in
                if let responseError = try? jsonDecoder.decode(ResponseDataModel.ServerError.self, from: data) {
                    // 伺服器回傳一個錯誤訊息
                    print("###", self, #function, "服務商表示錯誤", responseError.localizedDescription, responseError)
                    throw responseError
                } else {
                    return data
                }
            }
            .decode(type: ResponseDataModel.RateList.self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
}
