import Foundation

class HistoricalRateArchiver: BaseHistoricalRateArchiver {}

// MARK: - conforms to HistoricalRateProviderProtocol
extension HistoricalRateArchiver: HistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler) {
        if hasFileInDisk(historicalRateDateString: dateString) {
            do {
                let unarchivedHistoricalRate: ResponseDataModel.HistoricalRate = try unarchive(historicalRateDateString: dateString)
                resultHandler(.success(unarchivedHistoricalRate))
            }
            catch {
                nextHistoricalRateProvider.rateFor(dateString: dateString) { result in
                    if let fetchedHistoricalRate = try? result.get() {
                        DispatchQueue.global().async { [unowned self] in
                            try? archive(historicalRate: fetchedHistoricalRate)
                        }
                    }
                    
                    resultHandler(result)
                }
            }
        }
        else {
            nextHistoricalRateProvider.rateFor(dateString: dateString) { result in
                if let fetchedHistoricalRate = try? result.get() {
                    DispatchQueue.global().async { [unowned self] in
                        try? archive(historicalRate: fetchedHistoricalRate)
                    }
                }
                
                resultHandler(result)
            }
        }
    }
}
