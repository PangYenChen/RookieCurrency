import Foundation

class HistoricalRateProviderRing: BaseHistoricalRateProviderRing {}

extension HistoricalRateProviderRing: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           traceIdentifier: String,
                           resultHandler: @escaping HistoricalRateResultHandler) {
        if let storedRate = storage.readFor(dateString: dateString) {
            resultHandler(.success(storedRate))
        }
        else {
            nextProvider.historicalRateFor(dateString: dateString, traceIdentifier: traceIdentifier) { [unowned self] rateResult in
                switch rateResult {
                    case .success(let rate): storage.store(rate)
                    case .failure: break
                }
                resultHandler(rateResult)
            }
        }
    }
}
