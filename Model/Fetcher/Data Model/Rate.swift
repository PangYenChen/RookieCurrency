import Foundation

extension ResponseDataModel {
    typealias CurrencyCode = String
}

protocol RateCategoryProtocol {}

extension ResponseDataModel {
    
    /// 用來區別 latest 跟 historical 的 phantom type
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
        /// 貨幣跟匯率的鍵值對，1 單位新台幣等於多少其他貨幣
        let rates: [String: Decimal]
        
        subscript(currencyCode currencyCode: CurrencyCode) -> Decimal? {
            rates[currencyCode]
        }
        
        /// JSON 的 coding key
        enum CodingKeys: String, CodingKey {
            case date, timestamp, rates
        }
        
        private init(dateString: String, timestamp: Int, rates: [String : Decimal]) {
            self.dateString = dateString
            self.timestamp = timestamp
            self.rates = rates
            
            assertionFailure("###, \(#function), \(self), 刻意阻擋這個預設的 initializer")
        }
    }
}

// MARK: - type alias
extension ResponseDataModel {
    /// 用來裝 latest endpoint 的 data model
    typealias LatestRate = ResponseDataModel.Rate<ResponseDataModel.Category.Latest>
    /// 用來裝 historical endpoint 的 data model
    typealias HistoricalRate = ResponseDataModel.Rate<ResponseDataModel.Category.Historical>
}

// MARK: - Decodable
// latest 跟 historical 都要 decodable
extension ResponseDataModel.Rate: Decodable {
    /// 表示伺服器回傳的日期字串無效的錯誤
    enum ServerDateError: LocalizedError {
        /// 伺服器給的日期字串無效，dateString 為該字串
        case serverDateInvalid(dateString: String)
        
        var localizedDescription: String {
            switch self {
            case .serverDateInvalid(let dateString):
                return R.string.share.serverDateStringError(dateString)
            }
        }
        
        var errorDescription: String? {
            localizedDescription
        }
        
    }
    
    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        dateString = try container.decode(String.self, forKey: .date)
        
        // 客製化 init from decoder 就是為了檢查日期字串的格式
        guard AppUtility.requestDateFormatter.date(from: dateString) != nil else {
            throw ServerDateError.serverDateInvalid(dateString: dateString)
        }
        
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        
        rates = try container.decode([String: Decimal].self, forKey: .rates)
    }
}

// MARK: - Custom String Convertible
extension ResponseDataModel.Rate: CustomStringConvertible {
    var description: String { dateString }
}

// MARK: - Encodable
// 只有 historical rate 要存在本地，latest rate 不用
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

// MARK: - Equatable, Hashable
// historical 要放進 Set 裡面，latest 不用
extension ResponseDataModel.HistoricalRate: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dateString == rhs.dateString
    }
}

extension ResponseDataModel.HistoricalRate: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(dateString)
    }
}
