import Foundation

class BaseHistoricalRateCache {
    // MARK: - initializer
    init(historicalRateProvider: HistoricalRateProviderProtocol = HistoricalRateArchiver.shared) {
        nextHistoricalRateProvider = historicalRateProvider
        
        dateStringAndRateDirectory = [:]
        concurrentQueue = DispatchQueue(label: "historical.rate.cache", attributes: .concurrent)
    }
    
    // MARK: - private property
    var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate]
    let concurrentQueue: DispatchQueue
    
    let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

// MARK: - static property
extension HistoricalRateCache {
    static let shared: HistoricalRateCache = HistoricalRateCache()
}
