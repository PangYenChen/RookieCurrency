import Foundation

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
