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
            .flatMap(historicalRateProvider.publisherFor(dateString:))
            .collect(numberOfDays)
            .combineLatest(latestRateProvider.publisher()) { historicalRateArray, latestRate in (latestRate: latestRate, historicalRateSet: Set(historicalRateArray)) }
            .eraseToAnyPublisher()
    }
}
