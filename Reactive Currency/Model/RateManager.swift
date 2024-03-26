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
            .flatMap { [unowned self] dateString -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> in
                if let cacheHistoricalRate = concurrentQueue.sync(execute: { historicalRateDictionary[dateString] }) {
                    return Just(cacheHistoricalRate)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                else if archiver.hasFileInDisk(historicalRateDateString: dateString) {
                    return Future<ResponseDataModel.HistoricalRate, Error> { [unowned self] promise in
                        concurrentQueue.async(qos: .userInitiated) { [unowned self] in
                            do {
                                let unarchivedHistoricalRate: ResponseDataModel.HistoricalRate = try archiver.unarchive(historicalRateDateString: dateString)
                                concurrentQueue.async(qos: .userInitiated, flags: .barrier) { [unowned self] in
                                    historicalRateDictionary[unarchivedHistoricalRate.dateString] = unarchivedHistoricalRate
                                }
                                promise(.success(unarchivedHistoricalRate))
                            }
                            catch {
                                promise(.failure(error))
                            }
                        }
                    }
                    .catch { [unowned self] _ in
                        fetcher.publisher(for: Endpoints.Historical(dateString: dateString))
                            .handleEvents(
                                receiveOutput: { [unowned self] historicalRate in
                                    concurrentQueue.async(qos: .background, flags: .barrier) { [unowned self] in
                                        try? archiver.archive(historicalRate: historicalRate)
                                        historicalRateDictionary[historicalRate.dateString] = historicalRate
                                    }
                                }
                            )
                    }
                    .eraseToAnyPublisher()
                }
                else {
                    return fetcher.publisher(for: Endpoints.Historical(dateString: dateString))
                        .handleEvents(
                            receiveOutput: { [unowned self] historicalRate in
                                concurrentQueue.async(qos: .background, flags: .barrier) { [unowned self] in
                                    try? archiver.archive(historicalRate: historicalRate)
                                    historicalRateDictionary[historicalRate.dateString] = historicalRate
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
