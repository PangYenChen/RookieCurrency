import Foundation

protocol CurrencyDescriberProtocol {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String
}

class BaseSupportedCurrencyManager {
    // MARK: - initializer
    init(fetcher: FetcherProtocol = Fetcher.shared,
         locale: Locale = Locale.autoupdatingCurrent) {
        self.fetcher = fetcher
        self.locale = locale
    }

    // MARK: - instance properties
    let fetcher: FetcherProtocol
    
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
