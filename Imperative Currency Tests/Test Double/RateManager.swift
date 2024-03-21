import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    final class RateManager: RateManagerProtocol {
        private(set) var numberOfDays: Int?
        
        private var completionHandler: ((Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>) -> Void)?
        
        init() {
            numberOfDays = nil
        }
        
        func getRateFor(
            numberOfDays: Int,
            completionHandlerQueue: DispatchQueue,
            completionHandler: @escaping (Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>) -> Void) {
                self.numberOfDays = numberOfDays
                self.completionHandler = completionHandler
            }
        // TODO: completion handler 要用 typealias 跟 argument label
        
        func executeCompletionHandlerWith(result: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>) {
            completionHandler?(result)
            completionHandler = nil
        }
    }
}
