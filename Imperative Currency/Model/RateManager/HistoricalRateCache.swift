import Foundation

class HistoricalRateCache: BaseHistoricalRateCache {}

// MARK: - instance method
extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           historicalRateResultHandler: @escaping HistoricalRateResultHandler) {
        if let cachedHistoricalRate = concurrentQueue.sync(execute: { historicalRateDirectory[dateString] }) {
            historicalRateResultHandler(.success(cachedHistoricalRate))
        }
        else {
            nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { [unowned self] result in
                if let historicalRate = try? result.get() {
                    concurrentQueue.async(flags: .barrier) {
                        historicalRateDirectory[historicalRate.dateString] = historicalRate
                    }
                }
                historicalRateResultHandler(result)
            }
        }
    }
}
