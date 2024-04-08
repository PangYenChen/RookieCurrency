import Foundation

class HistoricalRateProviderChain: BaseHistoricalRateProviderChain {}

// MARK: - instance method
extension HistoricalRateProviderChain: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           resultHandler: @escaping HistoricalRateResultHandler) {
        nextHistoricalRateProvider.historicalRateFor(dateString: dateString,
                                                     resultHandler: resultHandler)
    }
}
