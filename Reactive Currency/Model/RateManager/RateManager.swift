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
        let id: String = UUID().uuidString
        
        return historicalRateDateStrings(numberOfDaysAgo: numberOfDays, from: start)
            .publisher
            .flatMap(historicalRateProvider.historicalRatePublisherFor(dateString:))
            .collect(numberOfDays)
            .combineLatest(latestRateProvider.latestRatePublisher()) { historicalRateArray, latestRate in (latestRate: latestRate, historicalRateSet: Set(historicalRateArray)) }
            .handleEvents(
                receiveSubscription: { [unowned self] _ in
                    logger.debug("start requesting rate for number of days: \(numberOfDays) from: \(start) with id: \(id)")
                },
                receiveOutput: { [unowned self] _ in
                    logger.debug("receive rate for number of days: \(numberOfDays) from: \(start) with id: \(id)")
                },
                receiveCompletion: { [unowned self] completion in
                    guard case .failure = completion else { return }
                    logger.debug("receive failure for number of days: \(numberOfDays) from: \(start) with id: \(id)")
                },
                receiveCancel: { [unowned self] in
                    logger.debug("receive cancel for number of days: \(numberOfDays) from: \(start) with id: \(id)")
                }
            )
            .eraseToAnyPublisher()
    }
}
