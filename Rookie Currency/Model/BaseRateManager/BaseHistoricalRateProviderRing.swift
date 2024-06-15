import OSLog

class BaseHistoricalRateProviderRing: BaseHistoricalRateProviderProtocol {
    init(storage: HistoricalRateStorageProtocol,
         nextProvider: HistoricalRateProviderProtocol) {
        self.storage = storage
        self.nextProvider = nextProvider
        
        logger = LoggerFactory.make(category: String(describing: Self.self) + " with " + String(describing: storage))
    }
    
    let storage: HistoricalRateStorageProtocol
    let nextProvider: HistoricalRateProviderProtocol
    
    let logger: Logger
    
    func removeAllStorage() {
        storage.removeAll()
    }
}
