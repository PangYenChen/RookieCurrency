//
//  Rate.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/28.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension ResponseDataModel {
    
    enum Category {
        enum Latest {}
        enum Historical {}
    }
    
    /// 服務商回傳的匯率資料
    /// Catetory 是 phantom type
    struct Rate<Category> {
        #warning("考慮拿掉")
        /// Returns true if a request for historical exchange rates was made.
        let historical: Bool
        
        /// Returns the date for which rates were requested.
        var dateString: String {
            AppSetting.requestDateFormatter.string(from: date)
        }
        
        /// 在拿到伺服器回傳的日期字串後，將該字串轉成 Date
        let date: Date
        
        /// Returns the exact date and time (UNIX time stamp) the given rates were collected.
        let timestamp: Int
        
        /// Returns the three-letter currency code of the base currency used for this request.
        /// 幣別跟匯率的鍵值對，1 歐元等於多少其他幣別
        let rates: [String: Double]
        
        subscript(_ currency: Currency) -> Double? {
            currency == .EUR ? 1 : rates[currency.rawValue]
        }
        
        /// JSON 的 coding key
        enum CodingKeys: String, CodingKey {
            case historical, date, timestamp, rates
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
        historical = (try container.decodeIfPresent(Bool.self, forKey: .historical)) ?? false
        let dateString = try container.decode(String.self, forKey: .date)
        
        // 客製化 init from decoder 就是為了檢查日期字串的格式
        if let dateDummy = AppSetting.requestDateFormatter.date(from: dateString) {
            date = dateDummy
        } else {
            throw ServerDateError.serverDateInvalid(dateString: dateString)
        }
        
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        
        rates = try container.decode([String: Double].self, forKey: .rates)
        
        for currency in Currency.allCases where currency != .EUR {
            guard rates[currency.rawValue] != nil else {
                throw ServerDateError.dataAbsent(currency.rawValue)
            }
        }
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
        try container.encode(historical, forKey: .historical)
        try container.encode(dateString, forKey: .date)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(rates, forKey: .rates)
    }
}

extension ResponseDataModel.HistoricalRate: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.date == rhs.date
    }
}

// historical 要放進 Set 裡面，latest 不用
extension ResponseDataModel.HistoricalRate: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }
}





