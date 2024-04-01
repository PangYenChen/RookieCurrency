import Foundation

class BaseHistoricalRateProvider {
    // MARK: - initializer
    init(nextHistoricalRateProvider: HistoricalRateProviderProtocol) {
        self.nextHistoricalRateProvider = nextHistoricalRateProvider
    }
    
    // MARK: - instance property
    let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

// MARK: - static property
extension HistoricalRateProvider {
    /// 實作的邏輯類似於 chain of responsibility，不過 chain 是固定的
    /// HistoricalRateProvider > HistoricalRateCache > HistoricalArchiver > Fetcher
    static let shared: HistoricalRateProvider = {
        let rateArchiver: HistoricalRateArchiver = HistoricalRateArchiver(nextHistoricalRateProvider: Fetcher.shared)
        let rateCache: HistoricalRateCache = HistoricalRateCache(historicalRateProvider: rateArchiver)
        
        return HistoricalRateProvider(nextHistoricalRateProvider: rateCache)
    }()
}
