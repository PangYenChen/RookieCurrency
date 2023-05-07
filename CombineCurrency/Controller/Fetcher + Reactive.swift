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
    func publisher<Endpoint: EndpointProtocol>(for endpoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Swift.Error> {
        
        func dataTaskPublisherWithLimitHandling(for endpoint: Endpoint) -> AnyPublisher<(data: Data, response: URLResponse), Swift.Error> {
            rateSession.rateDataTaskPublisher(for: createRequest(url: endpoint.url))
                .mapError { $0 }
                .flatMap { [unowned self] data, response -> AnyPublisher<(data: Data, response: URLResponse), Swift.Error> in
                    if let httpURLResponse = response as? HTTPURLResponse {
                        if httpURLResponse.statusCode == 401 {
                            // server 回應 status code 401，表示 api key 無效
                            if updateAPIKeySucceed() {
                                // 更新完 api key 後重新打 api
                                return dataTaskPublisherWithLimitHandling(for: endpoint)
                                    .eraseToAnyPublisher()
                            } else {
                                // 沒有有效 api key 可用
                                return Fail(error: Fetcher.Error.invalidAPIKey)
                                    .eraseToAnyPublisher()
                            }
                        } else if httpURLResponse.statusCode == 429 {
                            // server 回應 status code 429，表示 api key 額度用完
                            if updateAPIKeySucceed() {
                                // 更新完 api key 後重新打 api
                                return dataTaskPublisherWithLimitHandling(for: endpoint)
                                    .eraseToAnyPublisher()
                            } else {
                                // 已經沒有還有額度的 api key 可以用了
                                return Fail(error: Fetcher.Error.tooManyRequest)
                                    .eraseToAnyPublisher()
                            }
                        } else {
                            // 這是一切都正常的情況，把 data 跟 response 往下傳
                            return Just((data: data, response: response))
                                .setFailureType(to: Swift.Error.self)
                                .eraseToAnyPublisher()
                        }
                    } else {
                        assertionFailure("###, \(#function), \(self), response 不是 HttpURLResponse，常理來說都不會發生。")
                        return Fail(error: Error.unknownError)
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        }
        
        return dataTaskPublisherWithLimitHandling(for: endpoint)
            .map { $0.0 }
            .handleEvents(receiveOutput: AppUtility.prettyPrint)
            .decode(type: Endpoint.ResponseType.self, decoder: jsonDecoder)
            .eraseToAnyPublisher()
    }
}
