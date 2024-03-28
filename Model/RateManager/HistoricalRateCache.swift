import Foundation

class HistoricalRateCache {
    // MARK: - initializer
    init(historicalRateProvider: HistoricalRateProviderProtocol = Archiver.shared) {
        nextHistoricalRateProvider = historicalRateProvider
        
        historicalRateDirectory = [:]
        concurrentQueue = DispatchQueue(label: "historical.rate.cache", attributes: .concurrent)
    }
    
    // MARK: - private property
    private var historicalRateDirectory: [String: ResponseDataModel.HistoricalRate]
    private let concurrentQueue: DispatchQueue
    
    private let nextHistoricalRateProvider: HistoricalRateProviderProtocol
}

// TODO: 整個 extension 要刪掉
extension HistoricalRateCache {
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

// MARK: - instance method
extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String, 
                           historicalRateHandler: @escaping HistoricalRateHandler) {
        if let cachedHistoricalRate = concurrentQueue.sync(execute: { historicalRateDirectory[dateString] }) {
            historicalRateHandler(.success(cachedHistoricalRate))
        }
        else {
            nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { [unowned self] result in
                if let historicalRate = try? result.get() {
                    concurrentQueue.async(flags: .barrier) {
                        historicalRateDirectory[historicalRate.dateString] = historicalRate
                    }
                }
                historicalRateHandler(result)
            }
        }
    }
}

// MARK: - static property
extension HistoricalRateCache {
    static let shared: HistoricalRateCache = HistoricalRateCache()
}
