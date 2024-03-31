import Foundation

class HistoricalRateCache: BaseHistoricalRateCache {}

// MARK: - instance method
extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler) {
        if let cachedHistoricalRate = concurrentQueue.sync(execute: { historicalRateDirectory[dateString] }) {
            resultHandler(.success(cachedHistoricalRate))
        }
        else {
            nextHistoricalRateProvider.rateFor(dateString: dateString) { [unowned self] result in
                if let historicalRate = try? result.get() {
                    concurrentQueue.async(flags: .barrier) {
                        historicalRateDirectory[historicalRate.dateString] = historicalRate
                    }
                }
                resultHandler(result)
            }
        }
    }
}
