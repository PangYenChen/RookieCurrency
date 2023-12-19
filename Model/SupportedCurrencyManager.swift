import Foundation

class SupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager()
    
    private let fetcher: FetcherProtocol
    
    init(fetcher: FetcherProtocol = Fetcher.shared) {
        self.fetcher = fetcher
    }
}
