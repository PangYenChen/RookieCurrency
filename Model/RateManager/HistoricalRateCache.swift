import Foundation

extension BaseRateManager {
    class HistoricalRateCache {
        // MARK: - initializer
        init() {
            historicalRateDirectory = [:]
            concurrentQueue = DispatchQueue(label: "historical.rate.cache", attributes: .concurrent)
        }
        
        // MARK: - private property
        private var historicalRateDirectory: [String: ResponseDataModel.HistoricalRate]
        private let concurrentQueue: DispatchQueue
    }
}

extension BaseRateManager.HistoricalRateCache {
    func historicalRateFor(dateString: String) -> ResponseDataModel.HistoricalRate? {
        concurrentQueue.sync { historicalRateDirectory[dateString] }
    }
    
    func cache(_ historicalRate: ResponseDataModel.HistoricalRate) {
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            historicalRateDirectory[historicalRate.dateString] = historicalRate
        }
    }
    
    func removeAll() {
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            historicalRateDirectory.removeAll()
        }
    }
}
