//
//  Session Output.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/9/2.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import XCTest

extension TestingData {
    enum SessionData {
        static func latestRate() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data = TestingData.latestData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            
            
            let response = HTTPURLResponse(url: url,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)
            return (data, response, nil)
        }
        
        static func historicalRate(dateString: String) throws -> (data: Data?, response: URLResponse?, error: Error?) {
            
            let data = TestingData.historicalRateDataFor(dateString: dateString)
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)
            
            return (data, response, nil)
        }
        
        static func noContent() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            
            let data = Data()
            
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 204,
                                           httpVersion: nil,
                                           headerFields: nil)
            return (data, response, nil)
        }
        
        static func timeout() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            (nil, nil, URLError(URLError.timedOut))
        }
        
        static func tooManyRequest() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data = TestingData.tooManyRequestData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 429,
                                           httpVersion: nil,
                                           headerFields: nil)
            
            return (data: data, response: response, error: nil)
        }
        
        static func invalidAPIKey() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data = TestingData.invalidAPIKeyData
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 401,
                                           httpVersion: nil,
                                           headerFields: nil)
            
            return (data: data, response: response, error: nil)
        }
        
        static func supportedSymbols() throws -> (data: Data?, response: URLResponse?, error: Error?) {
            let data = TestingData.supportedSymbols
            let url = try XCTUnwrap(URL(string: "https://www.apple.com"))
            let response = HTTPURLResponse(url: url,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)
            
            return (data: data, response: response, error: nil)
        }
    }
}
