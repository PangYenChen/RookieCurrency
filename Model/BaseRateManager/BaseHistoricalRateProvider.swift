import Foundation

/// 實作的邏輯類似於 chain of responsibility，不過 chain 是固定的
/// HistoricalRateProvider > HistoricalRateCache > HistoricalArchiver > Fetcher
class BaseHistoricalRateProvider {
    // MARK: - initializer
    init() {
        historicalRateCache = HistoricalRateCache.shared
    }
    
    // MARK: - instance property
    let historicalRateCache: HistoricalRateCache
}

// MARK: - static property
extension HistoricalRateProvider {
    static let shared: HistoricalRateProvider = HistoricalRateProvider()
}
