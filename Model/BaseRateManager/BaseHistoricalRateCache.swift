import Foundation

class BaseHistoricalRateCache {
    // MARK: - initializer
    init(historicalRateProvider: HistoricalRateProviderProtocol) {
        nextHistoricalRateProvider = historicalRateProvider
        
        dateStringAndRateDirectory = [:]
        concurrentDispatchQueue = DispatchQueue(label: "historical.rate.cache", attributes: .concurrent)
    }
    
    // MARK: - private property
    var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate]
    let concurrentDispatchQueue: DispatchQueue
    
    let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

extension BaseHistoricalRateCache: BaseHistoricalRateProviderProtocol {
    func removeCachedAndStoredRate() {
        concurrentDispatchQueue.async(flags: .barrier) { [unowned self] in dateStringAndRateDirectory.removeAll() }
        
        nextHistoricalRateProvider.removeCachedAndStoredRate()
    }
}
