import Foundation

class HistoricalRateCache: BaseHistoricalRateCache {}

// MARK: - instance method
extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler) {
        if let cachedRate = concurrentDispatchQueue.sync(execute: { dateStringAndRateDirectory[dateString] }) {
            resultHandler(.success(cachedRate))
        }
        else {
            nextHistoricalRateProvider.rateFor(dateString: dateString) { [unowned self] result in
                if let historicalRate = try? result.get() {
                    concurrentDispatchQueue.async(flags: .barrier) {
                        dateStringAndRateDirectory[historicalRate.dateString] = historicalRate
                    }
                }
                resultHandler(result)
            }
        }
    }
}
