import Foundation
import OSLog

class HistoricalRateCache {
    init() {
        threadSafeDateStringAndRateDirectory = ThreadSafeWrapper<[String: ResponseDataModel.HistoricalRate]>(wrappedValue: [:])
        
        logger = LoggerFactory.make(category: String(describing: Self.self))
    }
    
    let threadSafeDateStringAndRateDirectory: ThreadSafeWrapper<[String: ResponseDataModel.HistoricalRate]>
    
    private let logger: Logger
}

extension HistoricalRateCache: HistoricalRateStorageProtocol {
    var description: String { String(describing: Self.self) }
    
    func readFor(dateString: String) -> ResponseDataModel.HistoricalRate? {
        threadSafeDateStringAndRateDirectory
            .readSynchronously { dateStringAndRateDirectory in
                if let historicalRate = dateStringAndRateDirectory[dateString] {
                    logger.debug("return a historical rate for date: \(dateString)")
                    
                    return historicalRate
                }
                else {
                    logger.debug("return nil for date: \(dateString)")
                    
                    return nil
                }
            }
    }
    
    func store(_ rate: ResponseDataModel.HistoricalRate) {
        threadSafeDateStringAndRateDirectory.writeAsynchronously { [weak self] dateStringAndRateDirectory in
            var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate] = dateStringAndRateDirectory
            dateStringAndRateDirectory[rate.dateString] = rate
            
            self?.logger.debug("store historical rate for date: \(rate.dateString)")
            
            return dateStringAndRateDirectory
        }
    }
    
    func removeAll() {
        threadSafeDateStringAndRateDirectory.writeAsynchronously { [weak self] _ in
            self?.logger.debug("remove all stored historical rate")
            
            return [:]
        }
    }
}
