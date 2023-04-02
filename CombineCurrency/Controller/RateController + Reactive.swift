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
    func publisher<Endpoint: EndpointProtocol>(for endPoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Swift.Error>
}

// MARK: - make Fetcher confirm FetcherProtocol
extension Fetcher: FetcherProtocol {}

#warning("這裡的 method 好長 看能不能拆開")

extension RateController {
    /// 獲得當下以及指定天數的歷史幣別匯率的資料
    /// - Parameter numberOfDay: 除了當下，所需歷史資料的天數
    /// - Returns: 送出所需的資料的 publisher
    func rateSetPublisher(forDays numberOfDay: Int)
    -> AnyPublisher<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> {
        
        fetcher.publisher(for: Endpoint.Latest())
            .flatMap { [unowned self] latestRate -> AnyPublisher<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> in
                
                let unarchivedRateSet = (try? Archiver.unarchive()) ?? []
                
                /// 在日期範圍內，需要向伺服器拿的資料
                var needToFetchRatePublisherArray = [AnyPublisher<ResponseDataModel.HistoricalRate, Error>]()
                
                /// 在日期範圍內，從硬碟中讀出來的資料
                var historicalRateNeededSet = Set<ResponseDataModel.HistoricalRate>()
                
                for numberOfDayAgo in 1...numberOfDay {
                    
#warning("這段應該要抽成一個 method")
                    let date = AppUtility.requestDateFormatter.date(from: latestRate.dateString)!
                    let historicalDate = date.advanced(by: 24 * 60 * 60 * Double(-numberOfDayAgo))
                    let historicalDateString = AppUtility.requestDateFormatter.string(from: historicalDate)
                    
                    
                    if let historicalRate = unarchivedRateSet.first(where: { $0.dateString == historicalDateString}) {
                        historicalRateNeededSet.insert(historicalRate)
                    } else {
                        needToFetchRatePublisherArray.append(
                            
                            fetcher.publisher(for: Endpoint.Historical(date: historicalDate))
                        )
                    }
                }
                
#warning("下面這個 if-else statement 很不漂亮，想要用 reactive 串起來")
                if needToFetchRatePublisherArray.isEmpty {
                    return Just((latestRate, historicalRateNeededSet))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    // 當能夠在歷史資料中，找到全部所需的資料時，publisher array 會是空的，此時 merge many 不會送出值。
                    return Publishers.MergeMany(needToFetchRatePublisherArray)
                        .collect(numberOfDay)
                        .tryMap { fetchRateArray -> [ResponseDataModel.HistoricalRate] in
                            let rateSet = Set(fetchRateArray).union(unarchivedRateSet)
                            try Archiver.archive(rateSet)
                            return fetchRateArray
                        }
                        .map { Set($0).union(historicalRateNeededSet) }
                        .map { (latestRate, $0) }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
