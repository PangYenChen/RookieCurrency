import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        // MARK: - initializer
        init() {
            dateStringAndHistoricalRateResultHandler = [:]
        }
        
        // MARK: - private property
        private(set) var dateStringAndHistoricalRateResultHandler: [String: HistoricalRateResultHandler]
        
        // MARK: - instance property
        func historicalRateFor(dateString: String,
                               resultHandler: @escaping HistoricalRateResultHandler) {
            dateStringAndHistoricalRateResultHandler[dateString] = resultHandler
        }
        
        func removeCachedAndStoredRate() {
            dateStringAndHistoricalRateResultHandler.removeAll()
        }
        
        func executeHistoricalRateResultHandlerFor(dateString: String,
                                                   with result: Result<ResponseDataModel.HistoricalRate, Error>) {
            dateStringAndHistoricalRateResultHandler.removeValue(forKey: dateString)?(result)
        }
    }
}
