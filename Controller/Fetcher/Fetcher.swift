//
//  Fetcher.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 跟伺服器拿資料的物件
class Fetcher {
    
    /// singleton object
    static let shared: Fetcher = .init()
    
    static let urlComponents: URLComponents? = {

        /// 拿匯率的 base url。
        /// 提供資料的服務商： https://apilayer.com/marketplace/category/currency
        let baseURL = "https://api.apilayer.com/exchangerates_data/"

        var urlComponents = URLComponents(string: baseURL)

        return urlComponents
    }()
    
    let rateSession: RateSession

    let jsonDecoder = JSONDecoder()
    
    init(rateSession: RateSession = Fetcher.rateSession) {
        self.rateSession = rateSession
    }
    
    // MARK: - api key 相關
    private var unusedAPIKeys: Set<String> = ["pT4L8AtpKOIWiGoE0ouiak003mdE0Wvg"]
    
    private var usingAPIKey: String = "kGm2uNHWxJ8WeubiGjTFhOG1uKs3iVsW"
    
    private var usedAPIKeys: Set<String> = []
    
#if DEBUG
    var apiKeysUsageRatio: Double {
        let totalAPIKeyCount = usedAPIKeys.count + 1 + unusedAPIKeys.count
        return Double(usedAPIKeys.count) / Double(totalAPIKeyCount)
    }
#endif
    
}

// MARK: - static property
extension Fetcher {
    /// 不暫存的 session
    private static let rateSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
}

// MARK: - helper method
extension Fetcher {
    /// 產生 timeout 時限為 5 秒，且帶上 api key 的 `URLRequest`
    /// - Parameter url: The URL to be retrieved.
    /// - Returns: The new url request.
    func createRequest(url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url, timeoutInterval: 5)
        urlRequest.addValue(usingAPIKey, forHTTPHeaderField: "apikey")
        return urlRequest
    }
    
    /// 更新正在使用的 api key
    /// 若還有新的 api key 可以用，換上後回傳 true，表示要重打 api。
    /// 若已無 api key 可用，回傳 false，讓 call cite 處理。
    /// - Returns: 是否需要從打一次 api
    func updateAPIKeySucceed() -> Bool {
        if unusedAPIKeys.isEmpty {
            // 已經沒有 api key 可以用了。
            return false
        } else {
            // 已經換上新的 api key，需要從打一次 api
            usedAPIKeys.insert(usingAPIKey)
            usingAPIKey = unusedAPIKeys.removeFirst()
            return true
        }
    }
    
    /// 把 `Data` 轉成好看的 JSON 字串印出來
    func prettyPrint(_ data: Data) {
#warning("考慮這個方法要不要跟 archiver 共用")
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            let jsonString = String(decoding: jsonData, as: UTF8.self)
            print("###", self, #function, "拿到 json:\n", jsonString)
        } else {
            print("###", self, #function, "json 格式無效")
        }
    }
}

// MARK: - name space
extension Fetcher {
    enum Error: LocalizedError {
        case noDataNoError
        case tooManyRequest
        
        var localizedDescription: String {
            switch self {
            case .noDataNoError:
                return "Something goes wrong (no data and error instance data task completion handler)"
            case .tooManyRequest:
                return "You have exceeded your daily/monthly API rate limit."
            }
            
        }
        
        var errorDescription: String? { localizedDescription }
    }
}
