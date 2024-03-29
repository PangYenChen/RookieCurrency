import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    final class RateManager: RateManagerProtocol {
        private(set) var numberOfDays: Int?
        
        private var completionHandler: ((Result<BaseRateManager.RateTuple, Error>) -> Void)?
        
        init() {
            numberOfDays = nil
        }
        
        func getRateFor(
            numberOfDays: Int,
            completionHandlerQueue: DispatchQueue,
            completionHandler: @escaping (Result<BaseRateManager.RateTuple, Error>) -> Void) {
                self.numberOfDays = numberOfDays
                self.completionHandler = completionHandler
            }
        
        func executeCompletionHandlerWith(result: Result<BaseRateManager.RateTuple, Error>) {
            completionHandler?(result)
            completionHandler = nil
        }
    }
}
