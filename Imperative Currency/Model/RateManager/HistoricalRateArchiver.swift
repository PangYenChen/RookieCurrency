import Foundation

class HistoricalRateArchiver: BaseHistoricalRateArchiver {}

// MARK: - conforms to HistoricalRateProviderProtocol
extension HistoricalRateArchiver: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           historicalRateResultHandler: @escaping HistoricalRateResultHandler) {
        if hasFileInDisk(historicalRateDateString: dateString) {
            do {
                let unarchivedHistoricalRate: ResponseDataModel.HistoricalRate = try unarchive(historicalRateDateString: dateString)
                historicalRateResultHandler(.success(unarchivedHistoricalRate))
            }
            catch {
                nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { result in
                    if let fetchedHistoricalRate = try? result.get() {
                        DispatchQueue.global().async { [unowned self] in
                            try? archive(historicalRate: fetchedHistoricalRate)
                        }
                    }
                    
                    historicalRateResultHandler(result)
                }
            }
        }
        else {
            nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { result in
                if let fetchedHistoricalRate = try? result.get() {
                    DispatchQueue.global().async { [unowned self] in
                        try? archive(historicalRate: fetchedHistoricalRate)
                    }
                }
                
                historicalRateResultHandler(result)
            }
        }
    }
}
