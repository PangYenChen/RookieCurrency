import Foundation

class HistoricalRateArchiver: BaseHistoricalRateArchiver {}

// MARK: - conforms to HistoricalRateProviderProtocol
extension HistoricalRateArchiver: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           resultHandler: @escaping HistoricalRateResultHandler) {
        if hasFileInDiskWith(dateString: dateString) {
            do {
                let unarchivedRate: ResponseDataModel.HistoricalRate = try unarchiveRateWith(dateString: dateString)
                resultHandler(.success(unarchivedRate))
            }
            catch {
                nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { result in
                    if let fetchedRate = try? result.get() {
                        DispatchQueue.global().async { [unowned self] in
                            try? archive(fetchedRate)
                        }
                    }
                    
                    resultHandler(result)
                }
            }
        }
        else {
            nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { result in
                if let fetchedRate = try? result.get() {
                    DispatchQueue.global().async { [unowned self] in
                        try? archive(fetchedRate)
                    }
                }
                
                resultHandler(result)
            }
        }
    }
}
