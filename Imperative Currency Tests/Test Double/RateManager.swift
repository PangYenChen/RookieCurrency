import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    final class RateManager: RateManagerProtocol {
        var numberOfDays: Int?
        
        var result: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ImperativeCurrency.ResponseDataModel.HistoricalRate>), Error>?
        
        init() {
            numberOfDays = nil
            result = nil
        }
        
        func getRateFor(
            numberOfDays: Int,
            completionHandlerQueue: DispatchQueue,
            completionHandler: @escaping (Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>) -> Void) {
                self.numberOfDays = numberOfDays
                guard let result else { return }
                completionHandler(result)
            }
        // TODO: completion handler 要用 typealias 跟 argument label
    }
}
