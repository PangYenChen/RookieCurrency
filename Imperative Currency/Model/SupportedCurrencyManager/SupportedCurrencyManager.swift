import Foundation

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    // MARK: - life cycle
    override init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
                  locale: Locale = Locale.autoupdatingCurrent,
                  serialDispatchQueue: DispatchQueue) {
        descriptionHandlers = []
        
        super.init(supportedCurrencyProvider: supportedCurrencyProvider,
                   locale: locale,
                   serialDispatchQueue: serialDispatchQueue)
    }
    
    private var descriptionHandlers: [DescriptionResultHandler]
    
    func getSupportedCurrency(descriptionHandler: @escaping DescriptionResultHandler) {
        serialDispatchQueue.sync { [unowned self] in
            if let cachedValue {
                descriptionHandler(.success(cachedValue))
            }
            else {
                descriptionHandlers.append(descriptionHandler)
                
                guard 1 == descriptionHandlers.count else { return }
                
                supportedCurrencyProvider.supportedCurrency { [unowned self] result in
                    serialDispatchQueue.async { [unowned self] in
                        let result: Result<[ResponseDataModel.CurrencyCode: String], Error> = result.map { supportedSymbols in supportedSymbols.symbols }
                        
                        if case .success(let currencyCodeDescriptions) = result {
                            cachedValue = currencyCodeDescriptions
                        }
                        
                        descriptionHandlers.forEach { descriptionHandler in descriptionHandler(result) }
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
