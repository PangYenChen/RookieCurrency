import Foundation

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager()
    // TODO: 這裡應該會有同時性問題，等我讀完 concurrency 之後再處理
    private var completionHandlers: [(Result<[ResponseDataModel.CurrencyCode: String], Error>) -> Void]
    
    override init(fetcher: FetcherProtocol = Fetcher.shared,
                  locale: Locale = Locale.autoupdatingCurrent) {
        completionHandlers = []
        
        super.init(fetcher: fetcher, locale: locale)
    }
    
    func fetchSupportedCurrency(completionHandler: @escaping (Result<[ResponseDataModel.CurrencyCode: String], Error>) -> Void) {
        
        if let supportedCurrencyDescriptionDictionary {
            completionHandler(.success(supportedCurrencyDescriptionDictionary))
        }
        else {
            completionHandlers.append(completionHandler)
            
            guard !completionHandlers.isEmpty else { return }
            
            fetcher.fetch(Endpoints.SupportedSymbols()) { [unowned self] result in
                if case .success(let supportedSymbols) = result {
                    self.supportedCurrencyDescriptionDictionary = supportedSymbols.symbols
                }
                while let completionHandler = self.completionHandlers.popLast() {
                    completionHandler(result.map { $0.symbols })
                }
            }
        }
    }
    
    func prefetchSupportedCurrency() {
        fetchSupportedCurrency { _ in }
    }
}
