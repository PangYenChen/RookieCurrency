//
//  RateController + Reactive.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

// MARK: - Fetcher Protocol
protocol FetcherProtocol {
    func publisher<Endpoint: EndpointProtocol>(for endpoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Swift.Error>
}

// MARK: - make Fetcher confirm FetcherProtocol
extension Fetcher: FetcherProtocol {}

#warning("這裡的 method 好長 看能不能拆開")

extension RateController {
    
    func ratePublisher(numberOfDay: Int, from start: Date = .now)
    -> AnyPublisher<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>
    {
        historicalRateDateStrings(numberOfDaysAgo: numberOfDay, from: start)
            .publisher
            .flatMap { [unowned self] dateString -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> in
                if let cacheHistoricalRate = concurrentQueue.sync(execute: { historicalRateDictionary[dateString] })  {
                    return Just(cacheHistoricalRate)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else if archiver.hasFileInDisk(historicalRateDateString: dateString) {
                    return Future<ResponseDataModel.HistoricalRate, Error> { [unowned self] promise in
                        concurrentQueue.async { [unowned self] in
                            do {
                                let unarchivedHistoricalRate = try archiver.unarchive(historicalRateDateString: dateString)
                                concurrentQueue.async(flags: .barrier) { [unowned self] in
                                    historicalRateDictionary[unarchivedHistoricalRate.dateString] = unarchivedHistoricalRate
                                }
                                promise(.success(unarchivedHistoricalRate))
                            } catch {
                                promise(.failure(error))
                            }
                        }
                    }
                    .catch { [unowned self] _ in
                        fetcher.publisher(for: Endpoint.Historical(dateString: dateString))
                            .handleEvents(
                                receiveOutput: { [unowned self] historicalRate in
                                    concurrentQueue.async(flags: .barrier) { [unowned self] in
                                        try? archiver.archive(historicalRate: historicalRate)
                                        historicalRateDictionary[historicalRate.dateString] = historicalRate
                                    }
                                }
                            )
                    }
                    .eraseToAnyPublisher()
                } else {
                    return fetcher.publisher(for: Endpoint.Historical(dateString: dateString))
                        .handleEvents(
                            receiveOutput: { [unowned self] historicalRate in
                                concurrentQueue.async(flags: .barrier) { [unowned self] in
                                    try? archiver.archive(historicalRate: historicalRate)
                                    historicalRateDictionary[historicalRate.dateString] = historicalRate
                                }
                            }
                        )
                        .eraseToAnyPublisher()
                }
            }
            .collect(numberOfDay)
            .combineLatest(fetcher.publisher(for: Endpoint.Latest()))
            .map { (latestRate: $0.1, historicalRateSet: Set($0.0)) }
            .eraseToAnyPublisher()
    }
}
