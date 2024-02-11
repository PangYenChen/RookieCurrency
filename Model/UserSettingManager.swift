import Foundation

protocol UserSettingManagerProtocol {
     var numberOfDays: Int { get set }
    
     var baseCurrencyCode: ResponseDataModel.CurrencyCode { get set }
    
     var resultOrder: BaseResultModel.Order { get set }
    
     var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> { get set }
}

// MARK: - user setting storage, including some specific fallback logic
class UserSettingManager: UserSettingManagerProtocol {
    // MARK: - initializer
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - instance property
    private let userDefaults: UserDefaults
}

// MARK: - instance computed properties
extension UserSettingManager {
    var numberOfDays: Int {
        get {
            let numberOfDaysInUserDefaults: Int = userDefaults.integer(forKey: Key.numberOfDays.rawValue)
            return numberOfDaysInUserDefaults > 0 ? numberOfDaysInUserDefaults : 3
        }
        set { userDefaults.set(newValue, forKey: Key.numberOfDays.rawValue) }
    }
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode {
        get {
            if let baseCurrencyCode = userDefaults.string(forKey: Key.baseCurrencyCode.rawValue) {
                return baseCurrencyCode
            }
            else {
                return "TWD"
            }
        }
        set {
            userDefaults.set(newValue, forKey: Key.baseCurrencyCode.rawValue)
        }
    }
    
    var resultOrder: BaseResultModel.Order {
        get {
            if let orderString = userDefaults.string(forKey: Key.resultOrder.rawValue),
               let order = BaseResultModel.Order(rawValue: orderString) {
                return order
            }
            else {
                return .increasing
            }
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Key.resultOrder.rawValue)
        }
    }
    
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> {
        get {
            if let currencyCodeOfInterest = userDefaults.stringArray(forKey: Key.currencyCodeOfInterest.rawValue) {
                return Set(currencyCodeOfInterest)
            }
            else {
                // 預設值為強勢貨幣(Hard Currency) 
                return ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
            }
        }
        set {
            userDefaults.setValue(newValue.sorted(), forKey: Key.currencyCodeOfInterest.rawValue)
        }
    }
}

// MARK: - static property
extension UserSettingManager {
    static let shared: UserSettingManager = UserSettingManager()
}

// MARK: - name space
extension UserSettingManager {
    private enum Key: String {
        case numberOfDays
        case baseCurrencyCode
        case resultOrder
        case currencyCodeOfInterest
    }
}
