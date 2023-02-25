//
//  RateListFetcher.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

/// 跟伺服器拿資料的物件
class RateListFetcher {
    
    /// /////////////這是新版本
    
    /// singleton object
    static let shared: RateListFetcher = .init()
    
    private let rookieURLSession: RookieURLSession
    #warning("之後要改成在 rate list controller decode")
    private let jsonDecoder = JSONDecoder()
    
    init(rookieURLSession: RookieURLSession = RateListFetcher.rookieURLSession) {
        self.rookieURLSession = rookieURLSession
    }
    
    private var apiKeys: [String] = [
        "pT4L8AtpKOIWiGoE0ouiak003mdE0Wvg"
    ]
    
    private var apiKey: String = "kGm2uNHWxJ8WeubiGjTFhOG1uKs3iVsW"
    
    func createRequest(url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url, timeoutInterval: 5)
        urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
        return urlRequest
    }
    
    func updateAPIKeySuccess() -> Bool {
        if let apiKey = apiKeys.popLast() {
            Self.apiKey = apiKey
            return true
        } else {
            return false
        }
    }
    
    
    
#if DEBUG
#warning("改成singleton的時候要改邏輯")
    var apiKeysUsage: Double {
        let apiKeyCount = apiKeys.count + 1
        return Double(apiKeys.count) / Double(apiKeyCount)
    }
#endif
    
    ////////////////這是舊版本
    
    /// 解析伺服器回傳的資料的共用 JSON decoder
    private static let jsonDecoder = JSONDecoder()
    
    /// 拿的資料的種類
    enum EndPoint {
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
                let dateString = DateFormatter.requestDateFormatter.string(from: date)
                urlComponents?.path += dateString
            }
            
            #warning("雖然說不應該 forced unwrap，但我想不到什麼時候會是 nil。")
            return (urlComponents?.url)!
        }
    }
    
    /// 不暫存的 session
    private static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
    
    private static let rookieURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
    
}

// MARK: - api keys
extension RateListFetcher {
    
    
    ////////////////這是新版本
    
    ////////////////這是舊版本
    private static var apiKeys: [String] = [
        "pT4L8AtpKOIWiGoE0ouiak003mdE0Wvg"
    ]
    
    private static var apiKey: String = "kGm2uNHWxJ8WeubiGjTFhOG1uKs3iVsW"
    
    static func createRequest(url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url, timeoutInterval: 5)
        urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
        return urlRequest
    }
    
    static func updateAPIKeySuccess() -> Bool {
        if let apiKey = apiKeys.popLast() {
            Self.apiKey = apiKey
            return true
        } else {
            return false
        }
    }
    
#if DEBUG
    #warning("改成singleton的時候要改邏輯")
    static var apiKeysUsage: Double {
        let apiKeyCount = apiKeys.count + 1
        return Double(apiKeys.count) / Double(apiKeyCount)
    }
#endif
}

// MARK: - helper method
extension RateListFetcher {
    #warning("考慮這個方法要不要跟 archiver 共用")
    private func prettyPrint(_ data: Data) {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            let jsonString = String(decoding: jsonData, as: UTF8.self)
            print("###", self, #function, "拿到 json:\n", jsonString)
        } else {
            print("###", self, #function, "json 格式無效")
        }
    }
    /// 印出好看的 JSON 格式字串
    /// - Parameter data: 要轉成字串的 data
    private static func prettyPrint(_ data: Data) {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            let jsonString = String(decoding: jsonData, as: UTF8.self)
            print("###", self, #function, "拿到 json:\n", jsonString)
        } else {
            print("###", self, #function, "json 格式無效")
        }
    }
}

// MARK: - Imperative Part
extension RateListFetcher {
    ////////////////這是新版本
    func fetchRateList(for endPoint: EndPoint,
                       completionHandler: @escaping (Result<ResponseDataModel.RateList, Error>) -> ()) {
        
        let urlRequest = createRequest(url: endPoint.url)
        
        urlSession.dataTask(with: urlRequest) { [unowned self] data, response, error in
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
        .resume()
    }
    ////////////////這是舊版本
    ///
    ///
    /// 向伺服器請求資料
    /// - Parameters:
    ///   - endPoint: 請求資料的種類
    ///   - completionHandler: 拿到資料後要執行的 completion handler
    static func fetchRateList(for endPoint: EndPoint,
                              completionHandler: @escaping (Result<ResponseDataModel.RateList, Error>) -> ()) {
        
        let urlRequest = createRequest(url: endPoint.url)
        
        urlSession.dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async {
                
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
        .resume()
    }
}



// MARK: - Combine Part
extension RateListFetcher {
    ////////////////這是新版本
    ///
    ///
    ////////////////這是舊版本
    /// 向伺服器請求資料
    /// - Parameter endPoint: 請求資料的種類
    /// - Returns: 送出伺服器回傳的 rate list 的 publisher
    static func rateListPublisher(for endPoint: EndPoint) -> AnyPublisher<ResponseDataModel.RateList, Error> {
        
        func dataTaskPublisherWithLimitHandling(for endPoint: EndPoint) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            let urlRequest = createRequest(url: endPoint.url)
            
            return urlSession.dataTaskPublisher(for: urlRequest)
                .receive(on: DispatchQueue.main)
                .flatMap { output -> AnyPublisher<(data: Data, response: URLResponse), URLError> in
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
            .tryMap { (data) -> Data in
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


protocol RookieURLSession {
    func rookieDataTask(with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void)
}

private extension URLSession: RookieURLSession {
#warning("想一下是不是要放在這，因為只有這用到")
    func rookieDataTask(with request: URLRequest,
                  completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) {
        dataTask(with: request, completionHandler: completionHandler).resume()
    }
}

