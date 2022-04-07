//
//  RookieURLSessionController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/7.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

/// 把 URLSession 包一層起來，統一將 timeout interval 設為 5 秒
enum RookieURLSessionController {
    /// timeout interval 設定為 5 秒
    static let timeoutInterval: TimeInterval = 5
    
    /// 不暫存的 session
    static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
}

// MARK: - Imperative Part
extension RookieURLSessionController {
    /// 產生 data task
    /// - Parameters:
    ///   - url: 索取資源的 url
    ///   - completionHandler: 拿到資料後要執行的 completion handler
    /// - Returns: timeout interval 為 5 秒的 data task
    static func dataTask(with url: URL,
                         completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionTask {
        let urlRequest = URLRequest(url: url, timeoutInterval: timeoutInterval)
        let dataTask = urlSession.dataTask(with: urlRequest) { (data, urlResponse, error) in
            completionHandler(data, urlResponse, error)
        }
        return dataTask
    }
}

// MARK: - Combine Part
extension RookieURLSessionController {
    /// 產生 data task publisher，包裝成 any publisher
    /// - Parameter url: 索取資源的 url
    /// - Returns: timeout interval 為 5 秒的 data task publisher
    static func dataTaskPublish(with url: URL) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure> {
        let urlRequest = URLRequest(url: url, timeoutInterval: timeoutInterval)
        return urlSession.dataTaskPublisher(for: urlRequest)
            .eraseToAnyPublisher()
    }
}


