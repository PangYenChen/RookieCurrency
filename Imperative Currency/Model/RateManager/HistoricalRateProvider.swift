import Foundation

class HistoricalRateProvider: BaseHistoricalRateProvider {}

// MARK: - instance method
extension HistoricalRateProvider: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           historicalRateResultHandler: @escaping HistoricalRateResultHandler) {
        historicalRateCache.historicalRateFor(dateString: dateString,
                                              historicalRateResultHandler: historicalRateResultHandler)
    }
}
