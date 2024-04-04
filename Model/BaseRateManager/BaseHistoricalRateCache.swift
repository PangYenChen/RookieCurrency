import Foundation

class BaseHistoricalRateCache {
    // MARK: - initializer
    init(historicalRateProvider: HistoricalRateProviderProtocol) {
        nextHistoricalRateProvider = historicalRateProvider
        
        dateStringAndRateDirectory = [:]
        concurrentQueue = DispatchQueue(label: "historical.rate.cache", attributes: .concurrent)
    }
    
    // MARK: - private property
    var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate]
    let concurrentQueue: DispatchQueue
    
    let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

extension BaseHistoricalRateCache: BaseHistoricalRateProviderProtocol {
    func removeCachedAndStoredRate() {
        concurrentQueue.async(flags: .barrier) { [unowned self] in dateStringAndRateDirectory.removeAll() }
        
        nextHistoricalRateProvider.removeCachedAndStoredRate()
    }
}
