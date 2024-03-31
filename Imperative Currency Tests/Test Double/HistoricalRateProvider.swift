import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        // MARK: - initializer
        init() {
            dateStringAndHistoricalRateResultHandler = [:]
        }
        
        // MARK: - private property
        private var dateStringAndHistoricalRateResultHandler: [String: HistoricalRateResultHandler]
        
        // MARK: - instance property
        func rateFor(dateString: String,
                     resultHandler: @escaping HistoricalRateResultHandler) {
            dateStringAndHistoricalRateResultHandler[dateString] = resultHandler
        }
        
        func executeHistoricalRateResultHandlerFor(dateString: String,
                                                   with result: Result<ResponseDataModel.HistoricalRate, Error>) {
            dateStringAndHistoricalRateResultHandler.removeValue(forKey: dateString)?(result)
        }
    }
}
