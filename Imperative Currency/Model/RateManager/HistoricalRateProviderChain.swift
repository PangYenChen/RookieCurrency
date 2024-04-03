import Foundation

class HistoricalRateProviderChain: BaseHistoricalRateProviderChain {}

// MARK: - instance method
extension HistoricalRateProviderChain: HistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler) {
        nextHistoricalRateProvider.rateFor(dateString: dateString,
                                           resultHandler: resultHandler)
    }
}
