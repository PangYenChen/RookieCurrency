import Foundation
import Combine

protocol RateManagerProtocol {
    func ratePublisher(numberOfDays: Int)
    -> AnyPublisher<BaseRateManager.RateTuple, Error>
}

class RateManager: BaseRateManager, RateManagerProtocol {
    func ratePublisher(numberOfDays: Int) -> AnyPublisher<BaseRateManager.RateTuple, Error> {
        ratePublisher(numberOfDays: numberOfDays, from: .now)
    }
    
    func ratePublisher(numberOfDays: Int, from start: Date) -> AnyPublisher<BaseRateManager.RateTuple, Error> {
        historicalRateDateStrings(numberOfDaysAgo: numberOfDays, from: start)
            .publisher
            .flatMap(historicalRateProvider.historicalRatePublisherFor(dateString:))
            .collect(numberOfDays)
            .combineLatest(latestRateProvider.publisher()) { (latestRate: $1, historicalRateSet: Set($0)) }
            .eraseToAnyPublisher()
    }
}
