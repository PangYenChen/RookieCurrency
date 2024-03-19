import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class RateManager: RateManagerProtocol {
        var numberOfDays: Int?
        
        var result: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>?
        
        init() {
            numberOfDays = nil
            result = nil
        }
        
        func ratePublisher(numberOfDays: Int) -> AnyPublisher<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> {
            self.numberOfDays = numberOfDays
            guard let result else { return Empty().eraseToAnyPublisher() }
            return result.publisher.eraseToAnyPublisher()
        }
    }
}
