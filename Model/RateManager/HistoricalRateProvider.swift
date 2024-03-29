import Foundation

/// 實作的邏輯類似於 chain of responsibility，不過 chain 是固定的
/// HistoricalRateProvider > HistoricalRateCache > Archiver > Fetcher
class HistoricalRateProvider: HistoricalRateProviderProtocol {
    // MARK: - initializer
    init() {
        historicalRateCache = HistoricalRateCache.shared
    }
    
    // MARK: - private property
    private let historicalRateCache: HistoricalRateCache
}

// MARK: - instance method
extension HistoricalRateProvider {
    func historicalRateFor(dateString: String,
                           historicalRateResultHandler: @escaping HistoricalRateResultHandler) {
        historicalRateCache.historicalRateFor(dateString: dateString,
                                              historicalRateResultHandler:  historicalRateResultHandler)
    }
}

// MARK: - static property
extension HistoricalRateProvider {
    static let shared: HistoricalRateProvider = HistoricalRateProvider()
}
