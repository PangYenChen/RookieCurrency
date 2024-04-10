import Foundation

class HistoricalRateCache {
    init() {
        threadSafeDateStringAndRateDirectory = ThreadSafeWrapper<[String: ResponseDataModel.HistoricalRate]>(wrappedValue: [:])
    }
    
    let threadSafeDateStringAndRateDirectory: ThreadSafeWrapper<[String: ResponseDataModel.HistoricalRate]>
}

extension HistoricalRateCache: HistoricalRateStorage {
    func readFor(dateString: String) -> ResponseDataModel.HistoricalRate? {
        threadSafeDateStringAndRateDirectory
            .readSynchronously { dateStringAndRateDirectory in dateStringAndRateDirectory[dateString] }
    }
    
    func store(_ rate: ResponseDataModel.HistoricalRate) {
        threadSafeDateStringAndRateDirectory.writeAsynchronously { dateStringAndRateDirectory in
            var dateStringAndRateDirectory = dateStringAndRateDirectory
            dateStringAndRateDirectory[rate.dateString] = rate
            
            return dateStringAndRateDirectory
        }
    }
    
    func removeCachedAndStoredRate() {
        threadSafeDateStringAndRateDirectory.writeAsynchronously { _ in [:] }
    }
}
