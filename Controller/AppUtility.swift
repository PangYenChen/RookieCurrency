import Foundation

/// 整個 App 通用的東西。
enum AppUtility {}

// MARK: - user setting storage, including so fallback logic
extension AppUtility {
    private enum Key: String {
        case numberOfDay
        case baseCurrency
        case order
        case currencyOfInterest
    }
    
    static var numberOfDay: Int {
        get {
            let numberOfDayInUserDefaults = UserDefaults.standard.integer(forKey: Key.numberOfDay.rawValue)
            return numberOfDayInUserDefaults > 0 ? numberOfDayInUserDefaults : 3
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.numberOfDay.rawValue) }
    }
    
    static var baseCurrency: ResponseDataModel.CurrencyCode {
        get {
            if let baseCurrencyCode = UserDefaults.standard.string(forKey: Key.baseCurrency.rawValue) {
                return baseCurrencyCode
            } else {
                return "TWD"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.baseCurrency.rawValue)
        }
    }
    
    static var order: BaseResultModel.Order {
        get {
            if let orderString = UserDefaults.standard.string(forKey: Key.order.rawValue),
               let order = BaseResultModel.Order(rawValue: orderString) {
                return order
            } else {
                return .increasing
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.order.rawValue)
        }
    }
    
    static var currencyOfInterest: Set<ResponseDataModel.CurrencyCode> {
        get {
            if let currencyOfInterest = UserDefaults.standard.stringArray(forKey: Key.currencyOfInterest.rawValue) {
                return Set(currencyOfInterest)
            } else {
                // 預設值為強勢貨幣(Hard Currency)
                return ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
            }
        }
        set {
            UserDefaults.standard.setValue(newValue.sorted(), forKey: Key.currencyOfInterest.rawValue)
        }
    }
    
    static var supportedSymbols: [ResponseDataModel.CurrencyCode: String]?
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
