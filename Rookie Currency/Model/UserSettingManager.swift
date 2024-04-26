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
    init(userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.userDefaults = userDefaults
        
        do /*initialize number of days*/ {
            let storedNumberOfDays: Int = userDefaults.integer(forKey: Key.numberOfDays.rawValue)
            defaultNumberOfDays = 3
            
            numberOfDays = storedNumberOfDays > 0 ? storedNumberOfDays : defaultNumberOfDays
        }
        
        do /*initialize base currency code*/ {
            let storedBaseCurrencyCode: ResponseDataModel.CurrencyCode? = userDefaults.string(forKey: Key.baseCurrencyCode.rawValue)
            defaultBaseCurrencyCode = "TWD"
            
            baseCurrencyCode = storedBaseCurrencyCode ?? defaultBaseCurrencyCode
        }
        
        do /*initialize currency code of interest*/ {
            let storedCurrencyCodeOfInterest: [ResponseDataModel.CurrencyCode]? = userDefaults.stringArray(forKey: Key.currencyCodeOfInterest.rawValue)
            // 預設值為強勢貨幣(Hard Currency)
            defaultCurrencyCodeOfInterest = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
            
            currencyCodeOfInterest = storedCurrencyCodeOfInterest.map(Set.init) ?? defaultCurrencyCodeOfInterest
        }
        
        do /*initialize result order*/ {
            let storedOrderString: String? = userDefaults.string(forKey: Key.resultOrder.rawValue)
            defaultResultOrder = .increasing
            
            resultOrder = storedOrderString.flatMap(BaseResultModel.Order.init(rawValue:)) ?? defaultResultOrder
        }
    }
    
    // MARK: - instance property
    private let userDefaults: UserDefaultsProtocol

    let defaultNumberOfDays: Int
    var numberOfDays: Int {
        didSet {
            guard oldValue != numberOfDays else { return }
            userDefaults.set(numberOfDays, forKey: Key.numberOfDays.rawValue)
        }
    }
    
    let defaultBaseCurrencyCode: ResponseDataModel.CurrencyCode
    var baseCurrencyCode: ResponseDataModel.CurrencyCode {
        didSet {
            guard oldValue != baseCurrencyCode else { return }
            userDefaults.set(baseCurrencyCode, forKey: Key.baseCurrencyCode.rawValue)
        }
    }
    
    let defaultCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> {
        didSet {
            guard oldValue != currencyCodeOfInterest else { return }
            userDefaults.set(currencyCodeOfInterest.sorted(), forKey: Key.currencyCodeOfInterest.rawValue)
        }
    }
    
    let defaultResultOrder: BaseResultModel.Order
    var resultOrder: BaseResultModel.Order {
        didSet {
            guard oldValue != resultOrder else { return }
            userDefaults.set(resultOrder.rawValue, forKey: Key.resultOrder.rawValue)
        }
    }
}

// MARK: - static property
extension UserSettingManager {
    static let shared: UserSettingManager = UserSettingManager()
}

// MARK: - name space
extension UserSettingManager {
    enum Key: String {
        case numberOfDays
        case baseCurrencyCode
        case resultOrder
        case currencyCodeOfInterest
    }
}
