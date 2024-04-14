import Foundation

class BaseSupportedCurrencyManager {
    init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
         locale: Locale,
         serialDispatchQueue: DispatchQueue) {
        self.supportedCurrencyProvider = supportedCurrencyProvider
        self.locale = locale
        
        cachedValue = nil
        self.serialDispatchQueue = serialDispatchQueue
    }
    
    let supportedCurrencyProvider: SupportedCurrencyProviderProtocol
    
    private let locale: Locale
    
    var cachedValue: CurrencyCodeDescriptions?
    
    let serialDispatchQueue: DispatchQueue
}

extension BaseSupportedCurrencyManager: CurrencyDescriberProtocol {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        locale.localizedString(forCurrencyCode: currencyCode)
        ??
        serialDispatchQueue.sync { cachedValue?[currencyCode] }
        ??
        currencyCode
    }
}

// MARK: - static property
extension SupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager(
        supportedCurrencyProvider: Fetcher.shared,
        serialDispatchQueue: DispatchQueue(label: "supported.currency.manager")
    )
}

extension BaseSupportedCurrencyManager {
    typealias CurrencyCodeDescriptions = [ResponseDataModel.CurrencyCode: String]
}
