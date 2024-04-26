class BaseHistoricalRateProviderRing: BaseHistoricalRateProviderProtocol {
    init(storage: HistoricalRateStorageProtocol,
         nextProvider: HistoricalRateProviderProtocol) {
        self.storage = storage
        self.nextProvider = nextProvider
    }
    
    let storage: HistoricalRateStorageProtocol
    let nextProvider: HistoricalRateProviderProtocol
    
    func removeAllStorage() {
        storage.removeAll()
    }
}
