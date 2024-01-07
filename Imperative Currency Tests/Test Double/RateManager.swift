import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    final class RateManager: RateManagerProtocol {
        var numberOfDays: Int?
        
        var result: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ImperativeCurrency.ResponseDataModel.HistoricalRate>), Error>
        
        init(result: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>) {
            self.numberOfDays = nil
            self.result = result
        }
        
        func getRateFor(
            numberOfDays: Int,
            completionHandlerQueue: DispatchQueue,
            completionHandler: @escaping (Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>) -> Void) {
                self.numberOfDays = numberOfDays
                completionHandler(result)
            }
    }
}
