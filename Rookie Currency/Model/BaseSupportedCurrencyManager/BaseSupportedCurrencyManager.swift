import Foundation

class BaseSupportedCurrencyManager {
    init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
         locale: Locale,
         internalSerialDispatchQueue: DispatchQueue) {
        self.supportedCurrencyProvider = supportedCurrencyProvider
        self.locale = locale
        
        cachedValue = nil
        self.internalSerialDispatchQueue = internalSerialDispatchQueue
    }
    
    let supportedCurrencyProvider: SupportedCurrencyProviderProtocol
    
    private let locale: Locale
    
    var cachedValue: CurrencyCodeDescriptions?
    
    let internalSerialDispatchQueue: DispatchQueue
}

extension BaseSupportedCurrencyManager: CurrencyDescriberProtocol {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        locale.localizedString(forCurrencyCode: currencyCode)
        ??
        internalSerialDispatchQueue.sync { cachedValue?[currencyCode] }
        ??
        currencyCode
    }
}

extension BaseSupportedCurrencyManager {
    typealias CurrencyCodeDescriptions = [ResponseDataModel.CurrencyCode: String]
}
