import Foundation

class HistoricalRateProviderRing: BaseHistoricalRateProviderRing {}

extension HistoricalRateProviderRing: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           traceIdentifier: String,
                           resultHandler: @escaping HistoricalRateResultHandler) {
        if let storedRate = storage.readFor(dateString: dateString) {
            logger.debug("trace identifier: \(traceIdentifier), read: \(dateString) from storage: \(self.storage.description)")
            resultHandler(.success(storedRate))
        }
        else {
            logger.debug("trace identifier: \(traceIdentifier), starting requesting: \(dateString) from next provider")
            nextProvider.historicalRateFor(dateString: dateString, traceIdentifier: traceIdentifier) { [unowned self] rateResult in
                switch rateResult {
                    case .success(let rate):
                        storage.store(rate)
                        logger.debug("trace identifier: \(traceIdentifier), receive historical rate for date: \(dateString)")
                    case .failure(let failure):
                        logger.debug("trace identifier: \(traceIdentifier), receive failure: \(failure) for date: \(dateString)")
                }
                resultHandler(rateResult)
            }
        }
    }
}
