import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        // MARK: - initializer
        init() {
            dateStringAndHistoricalRateResultHandlerDictionary = [:]
        }
        
        // MARK: - private property
        private(set) var dateStringAndHistoricalRateResultHandlerDictionary: [String: HistoricalRateResultHandler]
        
        // MARK: - instance property
        func historicalRateFor(dateString: String,
                               resultHandler: @escaping HistoricalRateResultHandler) {
            dateStringAndHistoricalRateResultHandlerDictionary[dateString] = resultHandler
        }
        
        func removeAllStorage() {
            dateStringAndHistoricalRateResultHandlerDictionary.removeAll()
        }
        
        func executeHistoricalRateResultHandlerFor(dateString: String,
                                                   with result: Result<ResponseDataModel.HistoricalRate, Error>) {
            dateStringAndHistoricalRateResultHandlerDictionary.removeValue(forKey: dateString)?(result)
        }
    }
}
