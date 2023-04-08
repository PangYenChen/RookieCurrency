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
    ///   - numberOfDay: <#numberOfDay description#>
    ///   - queue: <#queue description#>
    ///   - completionHandler: <#completionHandler description#>
    func getRateFor(
        numberOfDay: Int,
        queue: DispatchQueue,
        completionHandler: @escaping (Result<(latestRate: ResponseDataModel.LatestRate,
                                              historicalRateSet: Set<ResponseDataModel.HistoricalRate>),
                                      Error>) -> ()
    )
    {
        /// 硬碟中全部的資料
        var unarchivedRateSet = Set<ResponseDataModel.HistoricalRate>()
        /// 在日期範圍內的資料
        var historicalRateSet = Set<ResponseDataModel.HistoricalRate>()
        do {
            unarchivedRateSet = try Archiver.unarchive()
        } catch {
            DispatchQueue.main.async {
                completionHandler(.failure(error))
                print("###", self, #function, "從硬碟讀取資料失敗", error)
            }
            return
        }
        
        // 抓取當下的 rate
        fetcher.fetch(Endpoint.Latest()) { [unowned self] result in
            switch result {
            case .success(let latestRate):
                
                var dispatchGroup: DispatchGroup? = DispatchGroup()
                
                // 取得歷史資料
                for numberOfDayAgo in 1...numberOfDay {
                    
                    #warning("這段應該要抽成一個 method")
                    let date = AppUtility.requestDateFormatter.date(from: latestRate.dateString)!
                    let historicalDate = date.advanced(by: 24 * 60 * 60 * Double(-numberOfDayAgo))
                    let historicalDateString = AppUtility.requestDateFormatter.string(from: historicalDate)
                    
                    
                    if let historicalRate = unarchivedRateSet.first(where: { $0.dateString == historicalDateString}) {
                        // 有既有資料可以用
                        historicalRateSet.insert(historicalRate)
                        print("###", self, #function, "從既有的資料中找到：", historicalDate)
                    } else {
                        // 沒有既有資料，要透過網路拿取
                        print("###", self, #function, "向伺服器拿取資料：", historicalDate)
                        
                        dispatchGroup?.enter()
                        fetcher.fetch(Endpoint.Historical(date: historicalDate)) { result in
                            switch result {
                            case .success(let fetchedRate):
                                historicalRateSet.insert(fetchedRate)
                                unarchivedRateSet.insert(fetchedRate)
                                dispatchGroup?.leave()
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    completionHandler(.failure(error))
                                }
                                
                                dispatchGroup = nil
                            }
                        }
                    }
                }
                
                // 所需的資料全部拿到後
                dispatchGroup?.notify(queue: queue) {
                    print("###", self, #function, "全部的資料是\n\t", historicalRateSet.sorted { lhs, rhs in lhs.timestamp < rhs.timestamp })
                          
                    completionHandler(.success((latestRate, historicalRateSet)))
                    
                    try? Archiver.archive(unarchivedRateSet) // 不處理存檔失敗
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 新的寫法
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
                        self.fetcher.fetch(Endpoint.Historical(dateString: historicalRateDateString)) { [unowned self] result in
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
