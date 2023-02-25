//
//  RateListFetcher + Imperative.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension RateListFetcher {
    func fetchRateList(for endPoint: EndPoint,
                       completionHandler: @escaping (Result<ResponseDataModel.RateList, Error>) -> ()) {
        
        let urlRequest = createRequest(url: endPoint.url)
        
        rookieURLSession.rookieDataTask(with: urlRequest) { [unowned self] data, response, error in
            DispatchQueue.main.async { [unowned self] in
                
                // 當下的帳號（當下的 api key）的免費額度用完了
                if let httpURLResponse = response as? HTTPURLResponse,
                   httpURLResponse.statusCode == 429 {
                    // 換一個帳號（的 api key）打
                    if updateAPIKeySuccess() {
                        fetchRateList(for: endPoint, completionHandler: completionHandler)
                        return
                    }
                }
                
                // 網路錯誤，包含 timeout 跟所有帳號的免費額度都用完了
                if let error = error {
                    completionHandler(.failure(error))
                    print("###", self, #function, "網路錯誤", error.localizedDescription, error)
                    return
                }
                
                guard let data = data else {
                    print("###", self, #function, "沒有 data 也沒有 error，應該不會有這種情況。")
#warning("204 no content?")
#warning("這邊應該要硬 call completion handler 讓外面知道")
                    return
                }
                
                prettyPrint(data)
                
                if let responseError = try? jsonDecoder.decode(ResponseDataModel.ServerError.self, from: data) {
                    // 伺服器回傳一個錯誤訊息
                    completionHandler(.failure(responseError))
                    print("###", self, #function, "服務商表示錯誤", responseError.localizedDescription, responseError)
                    return
                }
                
                do {
                    let rateList = try jsonDecoder.decode(ResponseDataModel.RateList.self, from: data)
                    // 伺服器回傳正常的匯率資料
                    completionHandler(.success(rateList))
                    
                } catch {
                    completionHandler(.failure(error))
                    print("###", self, #function, "decode 失敗", error.localizedDescription, error)
                }
            }
        }
    }
}
