import Foundation

protocol BaseHistoricalRateProviderProtocol {
    func removeCachedAndStoredRate()
}

/// 實作的邏輯類似於 chain of responsibility，不過 chain 是固定的
/// HistoricalRateProviderChain > HistoricalRateCache > HistoricalArchiver > Fetcher
class BaseHistoricalRateProviderChain {
    // MARK: - initializer
    init(nextHistoricalRateProvider: HistoricalRateProviderProtocol) {
        self.nextHistoricalRateProvider = nextHistoricalRateProvider
    }
    
    // MARK: - instance property
    let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

// MARK: - instance method
extension BaseHistoricalRateProviderChain: BaseHistoricalRateProviderProtocol {
    func removeCachedAndStoredRate() {
        nextHistoricalRateProvider.removeCachedAndStoredRate()
    }
}

// MARK: - static property
extension HistoricalRateProviderChain {
    static let shared: HistoricalRateProviderChain = {
        let rateArchiver: HistoricalRateArchiver = HistoricalRateArchiver(nextHistoricalRateProvider: Fetcher.shared)
        let rateCache: HistoricalRateCache = HistoricalRateCache(historicalRateProvider: rateArchiver)
        
        return HistoricalRateProviderChain(nextHistoricalRateProvider: rateCache)
    }()
}
