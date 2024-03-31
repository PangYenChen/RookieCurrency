import Foundation

class HistoricalRateProvider: BaseHistoricalRateProvider {}

// MARK: - instance method
extension HistoricalRateProvider: HistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler) {
        historicalRateCache.rateFor(dateString: dateString,
                                    resultHandler: resultHandler)
    }
}
