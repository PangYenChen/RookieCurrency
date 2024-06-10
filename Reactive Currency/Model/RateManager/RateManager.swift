import Foundation
import Combine

class RateManager: BaseRateManager, RateManagerProtocol {
    func ratePublisher(numberOfDays: Int) -> AnyPublisher<BaseRateManager.RateTuple, Error> {
        ratePublisher(numberOfDays: numberOfDays, from: .now)
    }
    
    // the purpose of this method is to
    // inject the starting date when
    // testing ratePublisher(numberOfDays:)
    func ratePublisher(numberOfDays: Int,
                       from start: Date) -> AnyPublisher<BaseRateManager.RateTuple, Error> {
        historicalRateDateStrings(numberOfDaysAgo: numberOfDays, from: start)
            .publisher
            .flatMap { [weak self] historicalRateDateString in
                guard let self else { return Empty<ResponseDataModel.HistoricalRate, Error>().eraseToAnyPublisher() }
                return historicalRateProvider.historicalRatePublisherFor(dateString: historicalRateDateString, id: UUID().uuidString)
            }
            .collect(numberOfDays)
            .combineLatest(latestRateProvider.latestRatePublisher()) { historicalRateArray, latestRate in
                (latestRate: latestRate, historicalRateSet: Set(historicalRateArray))
            }
            .eraseToAnyPublisher()
    }
}
