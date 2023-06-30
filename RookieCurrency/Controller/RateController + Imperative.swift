//
//  RateController + Imperative.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

// MARK: - Fetcher Protocol
protocol FetcherProtocol {
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
    )
}

// MARK: - make Fetcher confirm FetcherProtocol
extension Fetcher: FetcherProtocol {}

#warning("這裡的 method 好長 看能不能拆開")
extension RateController {
    /// <#Description#>
    /// - Parameters:
    ///   - numberOfDays: <#numberOfDays description#>
    ///   - start: <#start description#>
    ///   - completionHandlerQueue: <#completionHandlerQueue description#>
    ///   - completionHandler: <#completionHandler description#>
    func getRateFor(
        numberOfDays: Int,
        from start: Date = .now,
        completionHandlerQueue: DispatchQueue = .main,
        completionHandler: @escaping (Result<(latestRate: ResponseDataModel.LatestRate,
                                              historicalRateSet: Set<ResponseDataModel.HistoricalRate>),
                                      Error>) -> ()
    )
    {
        var historicalRateSetResult: Result<Set<ResponseDataModel.HistoricalRate>, Error> = .success([])
        
        var dateStringsOfHistoricalRateInDisk: Set<String> = []
        
        var dateStringsOfHistoricalRateToFetch: Set<String> = []
        
        historicalRateDateStrings(numberOfDaysAgo: numberOfDays, from: start)
            .forEach { historicalRateDateString in
                if let cacheHistoricalRate = concurrentQueue.sync(execute: { historicalRateDictionary[historicalRateDateString] }) {
                    // rate controller 本身已經有資料了
                    historicalRateSetResult = historicalRateSetResult
                        .map { historicalRateSet in historicalRateSet.union([cacheHistoricalRate]) }
                } else if archiver.hasFileInDisk(historicalRateDateString: historicalRateDateString) {
                    // rate controller 沒資料，但硬碟裡有，叫 archiver 讀出來
                    dateStringsOfHistoricalRateInDisk.insert(historicalRateDateString)
                } else {
                    // 這台裝置上沒有資料，跟伺服器拿資料
                    dateStringsOfHistoricalRateToFetch.insert(historicalRateDateString)
                }
            }
        
        let dispatchGroup = DispatchGroup()
        
        // fetch historical rate
        dateStringsOfHistoricalRateToFetch
            .forEach { historicalRateDateString in
                dispatchGroup.enter()
                
                fetcher.fetch(Endpoint.Historical(dateString: historicalRateDateString)) { [unowned self] result in
                    switch result {
                    case .success(let fetchedHistoricalRate):
                        concurrentQueue.async { [unowned self] in
                            try? archiver.archive(historicalRate: fetchedHistoricalRate)
                        }
                        
                        concurrentQueue.async(flags: .barrier) { [unowned self] in
                            historicalRateSetResult = historicalRateSetResult
                                .map { historicalRateSet in historicalRateSet.union([fetchedHistoricalRate]) }
                            historicalRateDictionary[fetchedHistoricalRate.dateString] = fetchedHistoricalRate
                            dispatchGroup.leave()
                        }
                        
                    case .failure(let failure):
                        concurrentQueue.async(flags: .barrier) {
                            historicalRateSetResult = .failure(failure)
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        
        // read the file in disk
        dateStringsOfHistoricalRateInDisk
            .forEach { historicalRateDateString in
                dispatchGroup.enter()
                
                concurrentQueue.async { [unowned self] in
                    do {
                        let unarchivedHistoricalRate = try archiver.unarchive(historicalRateDateString: historicalRateDateString)
                        concurrentQueue.async(flags: .barrier) { [unowned self] in
                            historicalRateSetResult = historicalRateSetResult
                                .map { historicalRateSet in historicalRateSet.union([unarchivedHistoricalRate]) }
                            historicalRateDictionary[historicalRateDateString] = unarchivedHistoricalRate
                            dispatchGroup.leave()
                        }
                    } catch {
                        #warning("這段需要 unit test")
                        // fall back to fetch
                        fetcher.fetch(Endpoint.Historical(dateString: historicalRateDateString)) { [unowned self] result in
                            switch result {
                            case .success(let fetchedHistoricalRate):
                                concurrentQueue.async { [unowned self] in
                                    try? archiver.archive(historicalRate: fetchedHistoricalRate)
                                }
                                
                                concurrentQueue.async(flags: .barrier) { [unowned self] in
                                    historicalRateSetResult = historicalRateSetResult
                                        .map { historicalRateSet in historicalRateSet.union([fetchedHistoricalRate]) }
                                    historicalRateDictionary[historicalRateDateString] = fetchedHistoricalRate
                                    dispatchGroup.leave()
                                }
                            case .failure(let failure):
                                concurrentQueue.async(flags: .barrier) {
                                    historicalRateSetResult = .failure(failure)
                                    dispatchGroup.leave()
                                }
                            }
                        }
                    }
                }
            }
        
        // fetch latest rate
        var latestRateResult: Result<ResponseDataModel.LatestRate, Error>!
        
        dispatchGroup.enter()
        fetcher.fetch(Endpoint.Latest()) { result in
            latestRateResult = result
            dispatchGroup.leave()
        }
        
        // all enters have been set synchronously
        dispatchGroup.notify(queue: completionHandlerQueue) {
            do {
                let latestRate = try latestRateResult.get()
                let historicalRateSet = try historicalRateSetResult.get()
                completionHandler(.success((latestRate: latestRate, historicalRateSet: historicalRateSet)))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
