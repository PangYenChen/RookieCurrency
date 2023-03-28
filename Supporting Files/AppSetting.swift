//
//  AppSetting.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/26.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 使用者相關的設定。
/// 集中管理讀取不到資料時的 fall back 的邏輯。
enum AppSetting {}

// MARK: - user setting storage
extension AppSetting {
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
extension AppSetting {
    /// 能回傳 API 需要的日期格式的 date formatter
    /// 整個專案的日期都必須使用這個格式！
    /// 因為會有伺服器接受的只有到日期，沒有到分秒，
    /// 所以如果使用 Date 的 instance 的話，會有誤差。
    static let requestDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        // 好像不需要 Gregorian calendar 的樣子
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    /// 畫面上顯示的日期格式的 date formatter
    static let uiDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }()
}

// MARK: - JSONDecoder and JSONEncoder
extension AppSetting {
    static let jsonDecoder = JSONDecoder()
    
    static let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }()
}
