import Foundation

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    // MARK: - life cycle
    init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
         locale: Locale = Locale.autoupdatingCurrent,
         internalSerialDispatchQueue: DispatchQueue,
         externalConcurrentDispatchQueue: DispatchQueue) {
        descriptionHandlers = []
        self.externalConcurrentDispatchQueue = externalConcurrentDispatchQueue
        
        super.init(supportedCurrencyProvider: supportedCurrencyProvider,
                   locale: locale,
                   internalSerialDispatchQueue: internalSerialDispatchQueue)
    }
    
    private let externalConcurrentDispatchQueue: DispatchQueue
    
    private var descriptionHandlers: [DescriptionResultHandler]
    
    func getSupportedCurrency(descriptionHandler: @escaping DescriptionResultHandler) {
        internalSerialDispatchQueue.sync { [unowned self] in
            if let cachedValue {
                externalConcurrentDispatchQueue.async { descriptionHandler(.success(cachedValue)) }
            }
            else {
                descriptionHandlers.append(descriptionHandler)
                
                guard 1 == descriptionHandlers.count else { return }
                
                supportedCurrencyProvider.supportedCurrency { [unowned self] result in
                    internalSerialDispatchQueue.async { [unowned self] in
                        let result: Result<[ResponseDataModel.CurrencyCode: String], Error> = result.map { supportedSymbols in supportedSymbols.symbols }
                        
                        if case .success(let currencyCodeDescriptions) = result {
                            cachedValue = currencyCodeDescriptions
                        }
                        
                        descriptionHandlers.forEach { descriptionHandler in
                            externalConcurrentDispatchQueue.async { descriptionHandler(result) }
                        }
                            
                        descriptionHandlers.removeAll()
                    }
                }
            }
        }
    }
    
    func prefetchSupportedCurrency() {
        getSupportedCurrency { _ in }
    }
}

extension SupportedCurrencyManager {
    typealias DescriptionResultHandler = (_ result: Result<[ResponseDataModel.CurrencyCode: String], Error>) -> Void
}

extension SupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager(
        supportedCurrencyProvider: Fetcher.shared,
        internalSerialDispatchQueue: DispatchQueue(label: "supported.currency.manager.internal.serial"),
        externalConcurrentDispatchQueue: DispatchQueue(label: "supported.currency.manager.external.concurrent",
                                                       attributes: .concurrent)
    )
}
