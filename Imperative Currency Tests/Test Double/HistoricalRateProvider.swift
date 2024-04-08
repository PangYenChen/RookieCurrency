import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        // MARK: - initializer
        init() {
            dateStringAndHistoricalRateResultHandler = [:]
            numberOfCallOfRemoveCachedAndStoredRate = 0
        }
        
        // MARK: - private property
        private var dateStringAndHistoricalRateResultHandler: [String: HistoricalRateResultHandler]
        private(set) var numberOfCallOfRemoveCachedAndStoredRate: Int
        
        // MARK: - instance property
        func historicalRateFor(dateString: String,
                               resultHandler: @escaping HistoricalRateResultHandler) {
            dateStringAndHistoricalRateResultHandler[dateString] = resultHandler
        }
        
        func removeCachedAndStoredRate() { numberOfCallOfRemoveCachedAndStoredRate += 1 }
        
        func executeHistoricalRateResultHandlerFor(dateString: String,
                                                   with result: Result<ResponseDataModel.HistoricalRate, Error>) {
            dateStringAndHistoricalRateResultHandler.removeValue(forKey: dateString)?(result)
        }
    }
}
