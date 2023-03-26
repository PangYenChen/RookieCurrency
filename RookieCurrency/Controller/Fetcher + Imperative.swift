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
    /// 向服務商伺服器索取資料
    /// - Parameters:
    ///   - endpoint: The end point to be retrieved.
    ///   - completionHandler: The completion handler to call when the load request is complete.
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
    ) {
        let urlRequest = createRequest(url: endpoint.url)
        
        rateSession.rateDataTask(with: urlRequest) { [unowned self] data, response, error in
            if let httpURLResponse = response as? HTTPURLResponse, let data {
                if httpURLResponse.statusCode == 401 {
                    // status code 是 401 表示 api key 無效，要更新 api key 後重新打
                    if updateAPIKeySucceed() {
                        // 更新成功後重新打 api
                        fetch(endpoint, completionHandler: completionHandler)
                    } else {
                        // 沒有有效的 api key
                        completionHandler(.failure(Error.invalidAPIKey))
                        print("###, \(self), \(#function), api key 無效")
                    }
                } else if httpURLResponse.statusCode == 429 {
                    // status code 是 429 表示 api key 的額度已經用完，要更新 api key 後重新打
                    if updateAPIKeySucceed() {
                        // 更新成功後重新打 api
                        fetch(endpoint, completionHandler: completionHandler)
                    } else {
                        // 沒有還有額度的 api key
                        completionHandler(.failure(Error.tooManyRequest))
                        print("###, \(self), \(#function), api key 的額度用罄")
                    }
                } else {
                    prettyPrint(data)
                    // 這是一切正常的情況，將 data decode
                    do {
                        let rate = try jsonDecoder.decode(Endpoint.ResponseType.self, from: data)
                        completionHandler(.success(rate))
                    } catch {
                        completionHandler(.failure(error))
                        print("###, \(self), \(#function), decode 失敗, \(error.localizedDescription), \(error)")
                    }
                }
            } else if let error {
                // 網路錯誤，例如 timeout
                completionHandler(.failure(error))
                print("###", self, #function, "網路錯誤", error.localizedDescription, error)
            } else {
                assertionFailure("response 不是 HttpURLResponse，或者既沒有(data, httpURLResponse)，也沒有 error，常理來說都不會發生。")
                completionHandler(.failure(Error.unknownError))
            }
        }
    }
}
