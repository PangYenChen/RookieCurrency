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
    /// 把 URLSession 包一層起來，在測試的時候抽換掉。
    /// - Parameters:
    ///   - request: A URL request object that provides the URL, cache policy, request type, body data or body stream, and so on.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
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
    /// 像服務商伺服器索取資料
    /// - Parameters:
    ///   - endpoint: The end point to be retrieved.
    ///   - completionHandler: The completion handler to call when the load request is complete.
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
    ) {
        let urlRequest = createRequest(url: endpoint.url)
        
        rateSession.rateDataTask(with: urlRequest) { [unowned self] data, response, error in
            // api key 的額度是否用完
            if let response, let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 429 {
                if updateAPIKeySucceed() {
                    fetch(endpoint, completionHandler: completionHandler)
                } else {
                    completionHandler(.failure(Error.tooManyRequest))
                }
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
                completionHandler(.failure(Error.noDataNoError))
                return
            }
            
            prettyPrint(data)
            
            do {
                let rate = try jsonDecoder.decode(Endpoint.ResponseType.self, from: data)
                completionHandler(.success(rate))
            } catch {
                completionHandler(.failure(error))
                print("###, \(self), \(#function), decode 失敗, \(error.localizedDescription), \(error)")
            }
        }
    }
}
