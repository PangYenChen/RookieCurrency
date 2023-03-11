//
//  Rate.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/28.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

protocol RateCategoryProtocol {}

extension ResponseDataModel {
    
    enum Category {
        enum Latest: RateCategoryProtocol {}
        enum Historical: RateCategoryProtocol {}
    }
    
    /// 服務商回傳的匯率資料
    /// Catetory 是 phantom type
    struct Rate<Category: RateCategoryProtocol> {
        /// Returns the date for which rates were requested.
        let dateString: String
        
        /// Returns the exact date and time (UNIX time stamp) the given rates were collected.
        let timestamp: Int
        
        /// Returns the three-letter currency code of the base currency used for this request.
        /// 幣別跟匯率的鍵值對，1 歐元等於多少其他幣別
        let rates: [String: Double]
        
        subscript(_ currency: Currency) -> Double? {
            rates[currency.rawValue]
        }
        
        /// JSON 的 coding key
        enum CodingKeys: String, CodingKey {
            case date, timestamp, rates
        }
    }
}


extension ResponseDataModel.Rate: Decodable {
    
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
    
    
    
    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        dateString = try container.decode(String.self, forKey: .date)
        
        // 客製化 init from decoder 就是為了檢查日期字串的格式
        guard AppSetting.requestDateFormatter.date(from: dateString) != nil else {
            throw ServerDateError.serverDateInvalid(dateString: dateString)
        }
        
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        
        rates = try container.decode([String: Double].self, forKey: .rates)
    }
}

// MARK: - Custom String Convertible
extension ResponseDataModel.Rate: CustomStringConvertible {
    var description: String { dateString }
}

extension ResponseDataModel {
    typealias LatestRate = ResponseDataModel.Rate<ResponseDataModel.Category.Latest>
    typealias HistoricalRate = ResponseDataModel.Rate<ResponseDataModel.Category.Historical>
}



extension ResponseDataModel.HistoricalRate: Encodable {
    /// Encodes this value into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateString, forKey: .date)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(rates, forKey: .rates)
    }
}

extension ResponseDataModel.HistoricalRate: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dateString == rhs.dateString
    }
}

// historical 要放進 Set 裡面，latest 不用
extension ResponseDataModel.HistoricalRate: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(dateString)
    }
}

/// 表示幣別的 enum
enum Currency: String, CaseIterable {
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
#warning("考慮搬到其他地方去，這好像不屬於 data model，已經跟業務邏輯有關了。")
    var localizedString: String {
        if let localizedString =  Locale.current.localizedString(forCurrencyCode: self.rawValue) {
            return localizedString
        } else {
            switch self {
            case .TWD: return R.string.localizable.twD()
            case .USD: return R.string.localizable.usD()
            case .JPY: return R.string.localizable.jpY()
            case .EUR: return R.string.localizable.euR()
            case .CNY: return R.string.localizable.cnY()
            case .GBP: return R.string.localizable.gbP()
            case .SEK: return R.string.localizable.seK()
            case .CAD: return R.string.localizable.caD()
            case .ZAR: return R.string.localizable.zaR()
            case .HKD: return R.string.localizable.hkD()
            case .SGD: return R.string.localizable.sgD()
            case .CHF: return R.string.localizable.chF()
            case .NZD: return R.string.localizable.nzD()
            case .AUD: return R.string.localizable.auD()
            case .XAG: return R.string.localizable.xaG()
            case .XAU: return R.string.localizable.xaU()
            }
        }
    }
    
    var code: String { self.rawValue }
}



