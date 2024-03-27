import Foundation
import Combine

protocol RateManagerProtocol {
    func ratePublisher(numberOfDays: Int)
    -> AnyPublisher<BaseRateManager.RateTuple, Error>
}

// TODO: 這裡的 method 好長 看能不能拆開
class RateManager: BaseRateManager, RateManagerProtocol {
    func ratePublisher(numberOfDays: Int) -> AnyPublisher<BaseRateManager.RateTuple, Error> {
        ratePublisher(numberOfDays: numberOfDays, from: .now)
    }
    
    func ratePublisher(numberOfDays: Int, from start: Date)
    -> AnyPublisher<BaseRateManager.RateTuple, Error> {
        historicalRateDateStrings(numberOfDaysAgo: numberOfDays, from: start)
            .publisher
            .flatMap { [unowned self] historicalRateDateString -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> in
                if let cacheHistoricalRate = historicalRateCache.historicalRateFor(dateString: historicalRateDateString) {
                    return Just(cacheHistoricalRate)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                else if archiver.hasFileInDisk(historicalRateDateString: historicalRateDateString) {
                    return Future<ResponseDataModel.HistoricalRate, Error> { [unowned self] promise in
                        concurrentQueue.async(qos: .userInitiated) { [unowned self] in
                            do {
                                let unarchivedHistoricalRate: ResponseDataModel.HistoricalRate = try archiver.unarchive(historicalRateDateString: historicalRateDateString)
                                    historicalRateCache.cache(unarchivedHistoricalRate)
                                promise(.success(unarchivedHistoricalRate))
                            }
                            catch {
                                promise(.failure(error))
                            }
                        }
                    }
                    .catch { [unowned self] _ in
                        fetcher.publisher(for: Endpoints.Historical(dateString: historicalRateDateString))
                            .handleEvents(
                                receiveOutput: { [unowned self] historicalRate in
                                    historicalRateCache.cache(historicalRate)
                                    concurrentQueue.async(qos: .background, flags: .barrier) { [unowned self] in
                                        try? archiver.archive(historicalRate: historicalRate)
                                    }
                                }
                            )
                    }
                    .eraseToAnyPublisher()
                }
                else {
                    return fetcher.publisher(for: Endpoints.Historical(dateString: historicalRateDateString))
                        .handleEvents(
                            receiveOutput: { [unowned self] historicalRate in
                                historicalRateCache.cache(historicalRate)
                                concurrentQueue.async(qos: .background, flags: .barrier) { [unowned self] in
                                    try? archiver.archive(historicalRate: historicalRate)
                                }
                            }
                        )
                        .eraseToAnyPublisher()
                }
            }
            .collect(numberOfDays)
            .combineLatest(fetcher.publisher(for: Endpoints.Latest())) { (latestRate: $1, historicalRateSet: Set($0)) }
            .eraseToAnyPublisher()
    }
}
