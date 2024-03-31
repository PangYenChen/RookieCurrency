import Foundation

class HistoricalRateCache {
    // MARK: - initializer
    init(historicalRateProvider: HistoricalRateProviderProtocol = HistoricalRateArchiver.shared) {
        nextHistoricalRateProvider = historicalRateProvider
        
        historicalRateDirectory = [:]
        concurrentQueue = DispatchQueue(label: "historical.rate.cache", attributes: .concurrent)
    }
    
    // MARK: - private property
    private var historicalRateDirectory: [String: ResponseDataModel.HistoricalRate]
    private let concurrentQueue: DispatchQueue
    
    private let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

// MARK: - instance method
extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           historicalRateResultHandler: @escaping HistoricalRateResultHandler) {
        if let cachedHistoricalRate = concurrentQueue.sync(execute: { historicalRateDirectory[dateString] }) {
            historicalRateResultHandler(.success(cachedHistoricalRate))
        }
        else {
            nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { [unowned self] result in
                if let historicalRate = try? result.get() {
                    concurrentQueue.async(flags: .barrier) {
                        historicalRateDirectory[historicalRate.dateString] = historicalRate
                    }
                }
                historicalRateResultHandler(result)
            }
        }
    }
}

// MARK: - static property
extension HistoricalRateCache {
    static let shared: HistoricalRateCache = HistoricalRateCache()
}
