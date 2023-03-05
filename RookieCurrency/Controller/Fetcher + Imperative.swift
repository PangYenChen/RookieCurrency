//
//  Fetcher + Imperative.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

// MARK: - RateSession
protocol RateSession {
    func rateDataTask(with request: URLRequest,
                      completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

// MARK: - make url session confirm RateSession
extension URLSession: RateSession {
    func rateDataTask(with request: URLRequest,
                      completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        dataTask(with: request, completionHandler: completionHandler).resume()
    }
}

extension Fetcher {
    /// <#Description#>
    /// - Parameters:
    ///   - endpoint: <#endpoint description#>
    ///   - completionHandler: <#completionHandler description#>
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Error>) -> Void
    ) {
        let urlRequest = createRequest(url: endpoint.url)
        
        rateSession.rateDataTask(with: urlRequest) { [unowned self] data, response, error in
            // api key 的額度是否用完
            if let response, shouldMakeNewAPICall(for: response) {
                fetch(endpoint, completionHandler: completionHandler)
                return
            }
            
            // 網路錯誤，包含 timeout
            if let error = error {
                completionHandler(.failure(error))
                print("###", self, #function, "網路錯誤", error.localizedDescription, error)
                return
            }
            
            guard let data = data else {
                print("###", self, #function, "沒有 data 也沒有 error，一般來說如果碰到 status code 204 確實有可能沒有 data 跟 error，但這個服務商沒有這種情況。")
                completionHandler(.failure(FetcherError.noDataNoError))
                return
            }
            
            prettyPrint(data)
            
            do {
                let rate = try jsonDecoder.decode(Endpoint.ResponseType.self, from: data)
                completionHandler(.success(rate))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
