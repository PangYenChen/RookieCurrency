import Foundation

class BaseSupportedCurrencyManager {
    init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
         locale: Locale,
         internalSerialDispatchQueue: DispatchQueue,
         externalConcurrentDispatchQueue: DispatchQueue) {
        self.supportedCurrencyProvider = supportedCurrencyProvider
        self.locale = locale
        
        cachedValue = nil
        self.internalSerialDispatchQueue = internalSerialDispatchQueue
        self.externalConcurrentDispatchQueue = externalConcurrentDispatchQueue
    }
    
    let supportedCurrencyProvider: SupportedCurrencyProviderProtocol
    
    private let locale: Locale
    
    var cachedValue: CurrencyCodeDescriptions?
    
    let internalSerialDispatchQueue: DispatchQueue
    
    let externalConcurrentDispatchQueue: DispatchQueue
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

// MARK: - static property
extension SupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager(
        supportedCurrencyProvider: Fetcher.shared,
        internalSerialDispatchQueue: DispatchQueue(label: "supported.currency.manager.internal.serial"),
        externalConcurrentDispatchQueue: DispatchQueue(label: "supported.currency.manager.external.concurrent",
                                                       attributes: .concurrent)
    )
}

extension BaseSupportedCurrencyManager {
    typealias CurrencyCodeDescriptions = [ResponseDataModel.CurrencyCode: String]
}
