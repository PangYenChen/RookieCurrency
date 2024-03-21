import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class RateManager: RateManagerProtocol {
        var numberOfDays: Int?
        
        var result: Result<BaseRateManager.RateTuple, Error>?
        
        init() {
            numberOfDays = nil
            result = nil
        }
        
        func ratePublisher(numberOfDays: Int) -> AnyPublisher<BaseRateManager.RateTuple, Error> {
            self.numberOfDays = numberOfDays
            guard let result else { return Empty().eraseToAnyPublisher() }
            return result.publisher.eraseToAnyPublisher()
        }
    }
}
