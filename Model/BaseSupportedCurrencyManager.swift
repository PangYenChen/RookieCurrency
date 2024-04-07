import Foundation

protocol CurrencyDescriberProtocol {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String
}

class BaseSupportedCurrencyManager {
    // MARK: - initializer
    init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol = Fetcher.shared,
         locale: Locale = Locale.autoupdatingCurrent) {
        self.supportedCurrencyProvider = supportedCurrencyProvider
        self.locale = locale
    }

    // MARK: - instance properties
    let supportedCurrencyProvider: SupportedCurrencyProviderProtocol
    
    private let locale: Locale
    
    var supportedCurrencyDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]?
}

extension BaseSupportedCurrencyManager: CurrencyDescriberProtocol {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        locale.localizedString(forCurrencyCode: currencyCode) ??
        supportedCurrencyDescriptionDictionary?[currencyCode] ??
        currencyCode
    }
}

// MARK: - static property
extension SupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager()
}
