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
        
        /// 拿匯率的 base url，我使用的免費方案不支援 https。
        /// 提供資料的服務商： https://apilayer.com
        /// "https://api.apilayer.com/exchangerates_data/"
        /// "https://api.apilayer.com/fixer/"
        ///
        let baseURL = "https://api.apilayer.com/fixer/"
        
        var urlComponents = URLComponents(string: baseURL)
        
        urlComponents?.queryItems = [URLQueryItem(name: "base", value: "EUR")]
        
#warning("之後要改成以新台幣為基準幣別，這樣出錯的時候我比較看得出來，目前本地存的資料還是以歐元為基準")
        
        return urlComponents
    }()
    
    let rateListSession: RateListSession

    let jsonDecoder = JSONDecoder()
    
    init(rateListSession: RateListSession = Fetcher.rateListSession) {
        self.rateListSession = rateListSession
    }
    
    // MARK: - api key 相關
    private var apiKeys: [String] = [
        "pT4L8AtpKOIWiGoE0ouiak003mdE0Wvg"
    ]
    
    private var apiKey: String = "kGm2uNHWxJ8WeubiGjTFhOG1uKs3iVsW"
}

// MARK: - name space
extension Fetcher {
    /// 拿的資料的種類
    enum Endpoint {
        /// 組裝出 url 的 url components
        private static let urlComponents: URLComponents? = {

            /// 拿匯率的 base url，我使用的免費方案不支援 https。
            /// 提供資料的服務商： https://apilayer.com
            /// "https://api.apilayer.com/exchangerates_data/"
            /// "https://api.apilayer.com/fixer/"
            ///
            let baseURL = "https://api.apilayer.com/fixer/"

            var urlComponents = URLComponents(string: baseURL)

            urlComponents?.queryItems = [URLQueryItem(name: "base", value: "EUR")]

#warning("之後要改成以新台幣為基準幣別，這樣出錯的時候我比較看得出來，目前本地存的資料還是以歐元為基準")

            return urlComponents
        }()
        /// 當下的資料
        case latest
        /// 日期為 date 的歷史資料
        case historical(date: Date)

        /// 索取該資料的 url
        var url: URL {
            var urlComponents = Self.urlComponents

            switch self {
            case .latest:
                urlComponents?.path += "latest"
            case .historical(date: let date):
                let dateString = AppSetting.requestDateFormatter.string(from: date)
                urlComponents?.path += dateString
            }

#warning("雖然說不應該 forced unwrap，但我想不到什麼時候會是 nil。")
            return (urlComponents?.url)!
        }
    }
    
    /// 用來接著不明錯誤
    enum FetcherError: Error {
        case noDataNoError
    }
    
}

protocol EndpointProtocol {
    associatedtype ResponseType: Decodable
    
    var url: URL { get }
}


protocol PathProvider: EndpointProtocol {
    var path: String { get }
}

extension PathProvider {
    var url: URL {
        var urlComponents = Fetcher.urlComponents
        urlComponents?.path += path
        return (urlComponents?.url)!
    }
}




// MARK: - static property
extension Fetcher {
    /// 不暫存的 session
    private static let rateListSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
}

// MARK: - helper method
extension Fetcher {
    func createRequest(url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url, timeoutInterval: 5)
        urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
        return urlRequest
    }
    
    /// 判斷是否需要換新的 api key 重新打 api，是的話回傳是否更新 api key 成功。
    /// 當 api key 的額度用完時，server 會回傳 status code 429(too many request)，以此作為是否換 api key 的依據。
    /// 若還有新的 api key 可以用，換上後回傳 true
    /// 若以無 api key 可用，回傳 false
    /// - Parameter response: 前一次打 api 的 response
    /// - Returns: 是否需要從打一次 api
    func shouldMakeNewAPICall(for response: URLResponse) -> Bool {
        if let httpURLResponse = response as? HTTPURLResponse,
           httpURLResponse.statusCode == 429 {
            // 當下的 api key 的額度用完了，要換新的 api key
            if let apiKey = apiKeys.popLast() {
                // 已經換上新的 api key，需要從打一次 api
                self.apiKey = apiKey
                return true
            } else {
                // 已經沒有 api key 可以用了。
                return false
            }
        } else {
            // api key 的額度正常，不需要重打 api。
            return false
        }
    }
    
#warning("考慮這個方法要不要跟 archiver 共用")
    func prettyPrint(_ data: Data) {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            let jsonString = String(decoding: jsonData, as: UTF8.self)
            print("###", self, #function, "拿到 json:\n", jsonString)
        } else {
            print("###", self, #function, "json 格式無效")
        }
    }
}

// MARK: - 在 debug build configuration 顯示用量
#if DEBUG
extension Fetcher {
#warning("改成singleton的時候要改邏輯")
    var apiKeysUsage: Double {
        let apiKeyCount = apiKeys.count + 1
        return Double(apiKeys.count) / Double(apiKeyCount)
    }
}
#endif
