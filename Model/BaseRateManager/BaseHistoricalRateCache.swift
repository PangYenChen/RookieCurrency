import Foundation

class BaseHistoricalRateCache {
    // MARK: - initializer
    init(historicalRateProvider: HistoricalRateProviderProtocol) {
        nextHistoricalRateProvider = historicalRateProvider
        
        dateStringAndRateDirectoryWrapper = ThreadSafeWrapper<[String: ResponseDataModel.HistoricalRate]>(wrappedValue: [:])
    }
    
    let dateStringAndRateDirectoryWrapper: ThreadSafeWrapper<[String: ResponseDataModel.HistoricalRate]>
    
    let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

extension BaseHistoricalRateCache: BaseHistoricalRateProviderProtocol {
    func removeCachedAndStoredRate() {
        dateStringAndRateDirectoryWrapper.writeAsynchronously { _ in [:] }
    }
}
