//
//  Response Data Model.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/5/21.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 這是一個命名空間，容納伺服器回傳的資料所對應到的資料結構
enum ResponseDataModel {}

// MARK: - 伺服器會傳的正常資料 ResponseDataModel.RateList
extension ResponseDataModel {
    /// API 回傳的匯率資料
    struct RateList {
        
        /// Returns true if a request for historical exchange rates was made.
        let historical: Bool
        
        /// Returns the date for which rates were requested.
        var dateString: String {
            DateFormatter.requestDateFormatter.string(from: date)
        }
        
        /// 在拿到伺服器回傳的日期字串後，將該字串轉成 Date
        let date: Date
        
        /// Returns the exact date and time (UNIX time stamp) the given rates were collected.
        let timestamp: Int
        
        /// Returns the three-letter currency code of the base currency used for this request.
        /// 幣別跟匯率的鍵值對，1 歐元等於多少其他幣別
        let rates: Dictionary<String, Double>
        
        subscript(_ currency: Currency) -> Double? {
            currency == .EUR ? 1 : rates[currency.rawValue]
        }
        
        private init(historical: Bool, date: Date, timestamp: Int, rates: Dictionary<String, Double>) {
            fatalError("不應該用 decode 之外的方式產生 instance。")
        }
        
        /// 表示幣別的 enum
        enum Currency:String, CaseIterable {
            /// 新台幣
            case TWD
            /// 美金
            case USD
            /// 日圓
            case JPY
            /// 歐元
            case EUR
            /// 人民幣
            case CNY
            /// 英鎊
            case GBP
            /// 瑞典克朗
            case SEK
            /// 加拿大幣
            case CAD
            /// 南非幣
            case ZAR
            /// 港幣
            case HKD
            /// 新加坡幣
            case SGD
            /// 瑞士法郎
            case CHF
            /// 紐西蘭幣
            case NZD
            /// 澳幣
            case AUD
            /// 白銀 Silver (troy ounce)
            case XAG
            /// 黃金 Gold (troy ounce)
            case XAU
            
            var name: String {
                switch self {
                case .TWD: return "新台幣"
                case .USD: return "美金"
                case .JPY: return "日圓"
                case .EUR: return "歐元"
                case .CNY: return "人民幣"
                case .GBP: return "英鎊"
                case .SEK: return "瑞典克朗"
                case .CAD: return "加拿大幣"
                case .ZAR: return "南非幣"
                case .HKD: return "港幣"
                case .SGD: return "新加坡幣"
                case .CHF: return "瑞士法郎"
                case .NZD: return "紐西蘭幣"
                case .AUD: return "澳幣"
                case .XAG: return "白銀"
                case .XAU: return "黃金"
                }
            }
        }
    }
}

extension ResponseDataModel.RateList: Codable {
    
    /// 表示伺服器回傳的日期字串無效的錯誤
    enum ServerDateError: Error {
        /// 伺服器給的日期字串無效，date 為該字串
        case serverDateInvalid(dateString: String)
        case dataAbsent(String)
        
        var localizedDescription: String {
            switch self {
            case .serverDateInvalid(let string):
                return "伺服器回傳的日期字串是 \(string)"
            case .dataAbsent(let string):
                return "伺服器回傳的資料缺少 \(string)"
            }
        }
    }
    
    /// JSON 的 coding key
    enum CodingKeys: String, CodingKey {
        case historical, date, timestamp, rates
    }
    
    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        historical = (try container.decodeIfPresent(Bool.self, forKey: .historical)) ?? false
        let dateString = try container.decode(String.self, forKey: .date)
        
        // 客製化 init from decoder 就是為了檢查日期字串的格式
        if let dateDummy = DateFormatter.requestDateFormatter.date(from: dateString) {
            date = dateDummy
        } else {
            throw ServerDateError.serverDateInvalid(dateString: dateString)
        }
        
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        
        rates = try container.decode(Dictionary<String, Double>.self, forKey: .rates)
        
        for currency in ResponseDataModel.RateList.Currency.allCases where currency != .EUR {
            guard rates[currency.rawValue] != nil else {
                throw ServerDateError.dataAbsent(currency.rawValue)
            }
        }
    }
    
    /// Encodes this value into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(historical, forKey: .historical)
        try container.encode(dateString, forKey: .date)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(rates, forKey: .rates)
    }
}

extension ResponseDataModel.RateList: Equatable {
    static func == (lhs: ResponseDataModel.RateList, rhs: ResponseDataModel.RateList) -> Bool {
        lhs.date == rhs.date
    }
}

// 為了放進 Set 裡面
extension ResponseDataModel.RateList: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }
}

extension ResponseDataModel.RateList: CustomStringConvertible {
    var description: String { dateString}
}

// MARK: - 伺服器回傳的錯誤 ResponseDataModel.ServerError
extension ResponseDataModel {
    /// 伺服器回傳的錯誤，譬如說我沒付錢，用 https 的話，伺服器會回傳錯誤。
    struct ServerError {
        /// 服務商給的錯誤代碼，我不太確定是不是 HTTP 的 status code，
        /// 可以上服務商的網站查錯誤代碼的意思。
        let code: Int
        /// 服務商的文件沒說這是什麼，望文生義吧。
        let type: String?
        /// 服務商的文件沒說這是什麼，望文生義吧。
        let info: String
    }
    
    private init(code: Int, type: String?, info: String) {
        fatalError("不應該用 decode 之外的方式產生 instance。")
    }
}

extension ResponseDataModel.ServerError: Error {
    var localizedDescription: String {
        if let type = type {
            return "code: \(code), type: \(type), info: \(info)"
        } else {
            return "code: \(code), info: \(info)"
        }
    }
}

extension ResponseDataModel.ServerError: Decodable {
    /// JSON 第一層的 Coding Key
    enum CodingKeyForError: String, CodingKey {
        case error
    }
    
    /// JSON 第二層的 Coding Key
    enum CodingKeys: String, CodingKey {
        case code, type, info
    }
    
    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeyForError.self)
        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .error)
        
        code = try nestedContainer.decode(Int.self, forKey: .code)
        type = try? nestedContainer.decodeIfPresent(String.self, forKey: .type)
        info = try nestedContainer.decode(String.self, forKey: .info)
    }
}


