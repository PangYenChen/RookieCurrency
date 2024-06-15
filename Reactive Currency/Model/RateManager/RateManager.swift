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
        let traceIdentifier: String = UUID().uuidString
        
        logger.debug("trace identifier: \(traceIdentifier), start requesting rate for number of days: \(numberOfDays) from: \(start)")
        
        let historicalRateSetPublisher: AnyPublisher<Set<ResponseDataModel.HistoricalRate>, Error> = historicalRateDateStrings(numberOfDaysAgo: numberOfDays,
                                                                                                                               from: start)
            .publisher
            .flatMap { [weak self] historicalRateDateString in
                guard let self else { return Empty<ResponseDataModel.HistoricalRate, Error>().eraseToAnyPublisher() }
                return historicalRateProvider
                    .historicalRatePublisherFor(dateString: historicalRateDateString, traceIdentifier: traceIdentifier)
                    .handleEvents(receiveCompletion: { [weak self] completion in
                        guard case let .failure(failure) = completion else { return }
                        self?.logger.debug("trace identifier: \(traceIdentifier), receive failure: \(failure) from historical rate for number of days: \(numberOfDays) from: \(start)")
                    })
                    .eraseToAnyPublisher()
            }
            .collect(numberOfDays)
            .map(Set.init)
            .eraseToAnyPublisher()
        
        let latestRatePublisher: AnyPublisher<ResponseDataModel.LatestRate, Error> = latestRateProvider
            .latestRatePublisher(traceIdentifier: traceIdentifier)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard case let .failure(failure) = completion else { return }
                self?.logger.debug("trace identifier: \(traceIdentifier), receive failure: \(failure) from historical rate for number of days: \(numberOfDays) from: \(start)")
            })
            .eraseToAnyPublisher()
        
        return Publishers
            .CombineLatest(latestRatePublisher,
                           historicalRateSetPublisher)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.logger.debug("trace identifier: \(traceIdentifier), receive rate tuple for number of days: \(numberOfDays) from: \(start)")
            })
            .map { latestRate, historicalRateSet in (latestRate, historicalRateSet) }
            .eraseToAnyPublisher()
    }
}
