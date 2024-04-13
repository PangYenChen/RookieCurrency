import Foundation

class BaseSupportedCurrencyManager {
    init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol = Fetcher.shared,
         locale: Locale = Locale.autoupdatingCurrent) {
        self.supportedCurrencyProvider = supportedCurrencyProvider
        self.locale = locale
        
        cache = ThreadSafeWrapper<[ResponseDataModel.CurrencyCode: String]?>(wrappedValue: nil)
    }
    
    let supportedCurrencyProvider: SupportedCurrencyProviderProtocol
    
    private let locale: Locale
    
    var cache: ThreadSafeWrapper<[ResponseDataModel.CurrencyCode: String]?>
}

extension BaseSupportedCurrencyManager: CurrencyDescriberProtocol {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        locale.localizedString(forCurrencyCode: currencyCode) 
        ??
        cache.readSynchronously { supportedCurrencyDescriptionDictionary in
            supportedCurrencyDescriptionDictionary?[currencyCode]
        }
        ??
        currencyCode
    }
}

// MARK: - static property
extension SupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager()
}
