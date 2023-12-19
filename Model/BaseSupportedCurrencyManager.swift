import Foundation

class BaseSupportedCurrencyManager {
    let fetcher: FetcherProtocol
    
    private let locale: Locale
    
    // swiftlint:disable:next discouraged_optional_collection
    var supportedCurrencyDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]?
    
    init(fetcher: FetcherProtocol = Fetcher.shared,
         locale: Locale = Locale.autoupdatingCurrent) {
        self.fetcher = fetcher
        self.locale = locale
    }
    
    func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        locale.localizedString(forCurrencyCode: currencyCode) ??
        supportedCurrencyDescriptionDictionary?[currencyCode] ??
        currencyCode
    }
}
