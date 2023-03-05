//
//  RateController + Reactive.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine
#warning("這裡的 method 好長 看能不能拆開")

extension RateController {
    /// 獲得當下以及指定天數的歷史幣別匯率的資料
    /// - Parameter numberOfDay: 除了當下，所需歷史資料的天數
    /// - Returns: 送出所需的資料的 publisher
    func rateListSetPublisher(forDays numberOfDay: Int)
    -> AnyPublisher<(latestRateList: ResponseDataModel.LatestRate, historicalRateListSet: Set<ResponseDataModel.HistoricalRate>), Error> {
        
        fetcher.publisher(for: Endpoint.Latest())
            .flatMap { [unowned self] latestRate -> AnyPublisher<(latestRateList: ResponseDataModel.LatestRate, historicalRateListSet: Set<ResponseDataModel.HistoricalRate>), Error> in
                
                let unarchivedRateListSet = (try? Archiver.unarchive()) ?? []
                
                /// 在日期範圍內，需要向伺服器拿的資料
                var needToFetchRateListPublisherArray = [AnyPublisher<ResponseDataModel.HistoricalRate, Error>]()
                
                /// 在日期範圍內，從硬碟中讀出來的資料
                var historicalRateListNeededSet = Set<ResponseDataModel.HistoricalRate>()
                
                for numberOfDayAgo in 1...numberOfDay {
                    
#warning("這段應該要抽成一個 method")
                    let date = AppSetting.requestDateFormatter.date(from: latestRate.dateString)!
                    let historicalDate = date.advanced(by: 24 * 60 * 60 * Double(-numberOfDayAgo))
                    let historicalDateString = AppSetting.requestDateFormatter.string(from: historicalDate)
                    
                    
                    if let historicalRateList = unarchivedRateListSet.first(where: { $0.dateString == historicalDateString}) {
                        historicalRateListNeededSet.insert(historicalRateList)
                    } else {
                        needToFetchRateListPublisherArray.append(
                            
                            fetcher.publisher(for: Endpoint.Historical(date: historicalDate))
                        )
                    }
                }
                
#warning("下面這個 if-else statement 很不漂亮，想要用 reactive 串起來")
                if needToFetchRateListPublisherArray.isEmpty {
                    return Just((latestRate, historicalRateListNeededSet))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    // 當能夠在歷史資料中，找到全部所需的資料時，publisher array 會是空的，此時 merge many 不會送出值。
                    return Publishers.MergeMany(needToFetchRateListPublisherArray)
                        .collect(numberOfDay)
                        .tryMap { fetchRateListArray -> [ResponseDataModel.HistoricalRate] in
                            let rateListSet = Set(fetchRateListArray).union(unarchivedRateListSet)
                            try Archiver.archive(rateListSet)
                            return fetchRateListArray
                        }
                        .map { Set($0).union(historicalRateListNeededSet) }
                        .map { (latestRate, $0) }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
