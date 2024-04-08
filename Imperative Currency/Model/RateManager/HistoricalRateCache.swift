import Foundation

class HistoricalRateCache: BaseHistoricalRateCache {}

// MARK: - instance method
extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler) {
        let cachedRate: ResponseDataModel.HistoricalRate? = dateStringAndRateDirectoryWrapper
            .readSynchronously { dateStringAndRateDirectory in dateStringAndRateDirectory[dateString] }
        
        if let cachedRate {
            resultHandler(.success(cachedRate))
        }
        else {
            nextHistoricalRateProvider.rateFor(dateString: dateString) { [unowned self] result in
                if let historicalRate = try? result.get() {
                    dateStringAndRateDirectoryWrapper.writeAsynchronously { dateStringAndRateDirectory in
                        var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate] = dateStringAndRateDirectory
                        dateStringAndRateDirectory[historicalRate.dateString] = historicalRate
                        
                        return dateStringAndRateDirectory
                    }
                }
                resultHandler(result)
            }
        }
    }
}
