//
//  AppUtility.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/26.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 整個 App 通用的東西。
enum AppUtility {}

// MARK: - user setting storage
extension AppUtility {
    private enum Key: String {
        case numberOfDay
        case baseCurrency
        case order
    }
    
    static var numberOfDay: Int {
        get {
            let numberOfDayInUserDefaults = UserDefaults.standard.integer(forKey: Key.numberOfDay.rawValue)
            return numberOfDayInUserDefaults > 0 ? numberOfDayInUserDefaults : 30
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.numberOfDay.rawValue) }
    }
    
    static var baseCurrency: Currency {
        get {
            if let baseCurrencyString = UserDefaults.standard.string(forKey: Key.baseCurrency.rawValue),
               let baseCurrency = Currency(rawValue: baseCurrencyString) {
                return baseCurrency
            } else {
                return .TWD
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.baseCurrency.rawValue)
        }
    }
    
    static var order: ResultTableViewController.Order {
        get {
            if let orderString = UserDefaults.standard.string(forKey: Key.order.rawValue),
               let order = ResultTableViewController.Order(rawValue: orderString) {
                return order
            } else {
                return .increasing
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.order.rawValue)
        }
    }
    
}

// MARK: - formatter
extension AppUtility {
    /// 能回傳 API 需要的日期格式的 date formatter
    /// 整個專案的日期都必須使用這個格式！
    /// 因為會有伺服器接受的只有到日期，沒有到分秒，
    /// 所以如果使用 Date 的 instance 的話，會有誤差。
    static let requestDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC") // server time zone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
}

// MARK: - JSONDecoder and JSONEncoder
extension AppUtility {
    static let jsonDecoder = JSONDecoder()
    
    static let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }()
}

// MARK: - pretty print json
extension AppUtility {
    /// 把 data 轉乘 json 格式的字串，並在 console 顯示
    /// - Parameter data: 要轉的 data
    static func prettyPrint(_ data: Data) {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            let jsonString = String(decoding: jsonData, as: UTF8.self)
            print("###", self, #function, "拿到 json:\n", jsonString)
        } else {
            print("###", self, #function, "json 格式無效")
        }
    }
}
