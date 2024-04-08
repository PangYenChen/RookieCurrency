import Foundation

class HistoricalRateCache: BaseHistoricalRateCache {}

// MARK: - instance method
extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           resultHandler: @escaping HistoricalRateResultHandler) {
        let cachedRate: ResponseDataModel.HistoricalRate? = dateStringAndRateDirectoryWrapper
            .readSynchronously { dateStringAndRateDirectory in dateStringAndRateDirectory[dateString] }
        
        if let cachedRate {
            resultHandler(.success(cachedRate))
        }
        else {
            nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { [unowned self] result in
                if let rate = try? result.get() {
                    dateStringAndRateDirectoryWrapper.writeAsynchronously { dateStringAndRateDirectory in
                        var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate] = dateStringAndRateDirectory
                        dateStringAndRateDirectory[rate.dateString] = rate
                        
                        return dateStringAndRateDirectory
                    }
                }
                resultHandler(result)
            }
        }
    }
}
