import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        init() {
            dateStringAndHistoricalRateResultHandlerDictionary = [:]
            
            numberOfRemoveAllStorageCall = 0
        }
        
        private(set) var dateStringAndHistoricalRateResultHandlerDictionary: [String: HistoricalRateResultHandler]
        
        private(set) var numberOfRemoveAllStorageCall: Int
        
        func historicalRateFor(dateString: String,
                               resultHandler: @escaping HistoricalRateResultHandler) {
            dateStringAndHistoricalRateResultHandlerDictionary[dateString] = resultHandler
        }
        
        func removeAllStorage() {
            numberOfRemoveAllStorageCall += 1
            dateStringAndHistoricalRateResultHandlerDictionary.removeAll()
        }
        
        func executeHistoricalRateResultHandlerFor(dateString: String,
                                                   with result: Result<ResponseDataModel.HistoricalRate, Error>) {
            dateStringAndHistoricalRateResultHandlerDictionary.removeValue(forKey: dateString)?(result)
        }
    }
}
