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
enum RateListFetcher {
    // 提供資料的服務商： https://fixer.io
    
    /// 拿匯率的 base url，我使用的免費方案不支援 https。
    private static let baseURL = "http://data.fixer.io/api/"
    
    /// 組裝出 url 的 url components
    private static let urlComponents: URLComponents? = {
        var urlComponents = URLComponents(string: baseURL)
        
        let accessKey = "cab92b8eb8df1c00d9913e9701776955"
        let symbolQueryValue = "TWD,JPY,USD,CNY,GBP,SEK,CAD,ZAR,HKD,SGD,CHF,NZD,AUD,XAG,XAU"
        
        urlComponents?.queryItems = [
            URLQueryItem(name: "access_key", value: accessKey),
            URLQueryItem(name: "symbols", value: symbolQueryValue)
        ]
        
        return urlComponents
    }()
    
    /// 解析伺服器回傳的資料的共用 JSON decoder
    private static let jsonDecoder = JSONDecoder()
    
    /// 拿的資料的種類
    enum EndPoint {
        /// 當下的資料
        case latest
        /// 日期為 date 的歷史資料
        case historical(date: Date)
        
        /// 索取該資料的 url
        var url: URL {
            var dummyUrlComponents = urlComponents
            
            switch self {
            case .latest:
                dummyUrlComponents?.path += "latest"
            case .historical(date: let date):
                let dateString = DateFormatter.requestDateFormatter.string(from: date)
                dummyUrlComponents?.path += dateString
            }
            
            #warning("雖然說不應該 forced unwrap，但我想不到什麼時候會是 nil。")
            return (dummyUrlComponents?.url)!
        }
    }
    
    /// 印出好看的 JSON 格式字串
    /// - Parameter data: 要轉成字串的 data
    private static func prettyPrint(_ data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data),
            let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            print("###", self, #function, "拿到 json:\n", String(decoding: jsonData, as: UTF8.self))
        } else {
            print("###", self, #function, "json 格式無效")
        }
    }
}

// MARK: - Imperative Part
extension RateListFetcher {
    #warning("好長的 method...... 拆拆看吧")
    /// 向伺服器請求資料
    /// - Parameters:
    ///   - endPoint: 請求資料的種類
    ///   - completionHandler: 拿到資料後要執行的 completion handler
    static func fetchRateList(for endPoint: EndPoint,
                          completionHandler: @escaping (Result<ResponseDataModel.RateList, Error>) -> ()) {
        
        RookieURLSessionController.dataTask(with: endPoint.url) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completionHandler(.failure(error))
                    print("###", self, #function, "網路錯誤", error.localizedDescription, error)
                    return
                }
                
                #warning("這個不知道怎麼處理，應該不會再沒有 error 的情況下也沒有 data 吧？")
                guard let data = data else { print("###", self, #function, "沒有data"); return}
                
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
        }.resume()
    }
}



// MARK: - Combine Part
extension RateListFetcher {
    /// 向伺服器請求資料
    /// - Parameter endPoint: 請求資料的種類
    /// - Returns: 送出伺服器回傳的 rate list 的 publisher
    static func rateListPublisher(for endPoint: EndPoint) -> AnyPublisher<ResponseDataModel.RateList, Error> {
        return RookieURLSessionController.dataTaskPublish(with: endPoint.url)
            .receive(on: DispatchQueue.main)
            .map { $0.0}
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


