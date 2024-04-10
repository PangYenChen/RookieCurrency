class HistoricalRateProviderRing: HistoricalRateProviderProtocol {
    init(storage: HistoricalRateStorageProtocol,
         nextProvider: HistoricalRateProviderProtocol) {
        self.storage = storage
        self.nextProvider = nextProvider
    }
    
    let storage: HistoricalRateStorageProtocol
    let nextProvider: HistoricalRateProviderProtocol
    
    func historicalRateFor(dateString: String, resultHandler: @escaping HistoricalRateResultHandler) {
        if let storedRate = storage.readFor(dateString: dateString) {
            resultHandler(.success(storedRate))
        }
        else {
            nextProvider.historicalRateFor(dateString: dateString) { [unowned self] rateResult in
                switch rateResult {
                    case .success(let rate): storage.store(rate)
                    case .failure: break
                }
                resultHandler(rateResult)
            }
        }
    }
    
    func removeCachedAndStoredRate() {
        storage.removeCachedAndStoredRate()
    }
}
