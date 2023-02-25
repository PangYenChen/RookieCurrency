//
//  RateListFetcher + Imperative.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension RateListFetcher {
    /// <#Description#>
    /// - Parameters:
    ///   - endPoint: <#endPoint description#>
    ///   - completionHandler: <#completionHandler description#>
    func rateList(for endPoint: EndPoint,
                  completionHandler: @escaping (Result<Data, Error>) -> ()) {
        
        let urlRequest = createRequest(url: endPoint.url)
        
        rateListSession.rateListDataTask(with: urlRequest) { [unowned self] data, response, error in
            // api key 的額度是否用完
            if let response, shouldMakeNewAPICall(for: response) {
                    rateList(for: endPoint, completionHandler: completionHandler)
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
            
            if let responseError = try? jsonDecoder.decode(ResponseDataModel.ServerError.self, from: data) {
                // 伺服器回傳一個錯誤訊息
                completionHandler(.failure(responseError))
                print("###", self, #function, "服務商表示錯誤", responseError.localizedDescription, responseError)
                return
            } else {
                completionHandler(.success(data))
            }
        }
    }
}
