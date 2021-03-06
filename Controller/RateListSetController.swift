//
//  RateListSetController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine
#warning("這裡的 method 好長 看能不能拆開")
/// 用來獲得各幣別匯率資料的類別
enum RateListSetController {}

// MARK: - Imperative Part
extension RateListSetController {
    /// 獲得當下以及指定天數的歷史幣別匯率的資料
    /// - Parameters:
    ///   - numberOfDay: 除了當下，所需歷史資料的天數
    ///   - completionHandler: 拿到資料後要執行的 completion handler
    static func getRatesSetForDays(numberOfDay: Int,
                                   completionHandler: @escaping (Result<(latestRateList: ResponseDataModel.RateList, historicalRateListSet: Set<ResponseDataModel.RateList>), Error>) -> ()) {
        
        /// 硬碟中全部的資料
        var unarchivedRateListSet = Set<ResponseDataModel.RateList>()
        /// 在日期範圍內的資料
        var historicalRateListSet = Set<ResponseDataModel.RateList>()
        do {
            unarchivedRateListSet = try RateListSetArchiver.unarchive()
        } catch {
            completionHandler(.failure(error))
            print("###", self, #function, "從硬碟讀取資料失敗", error)
            return
        }
        
        // 抓取當下的 rate list
        RateListFetcher.fetchRateList(for: .latest) { result in
            switch result {
            case .success(let latestRateList):
                
                var dispatchGroup: DispatchGroup? = DispatchGroup()
                
                // 取得歷史資料
                for numberOfDayAgo in 1...numberOfDay {
                    let historicalDate = latestRateList.date.advanced(by: 24 * 60 * 60 * Double(-numberOfDayAgo))
                    if let historicalRateList = unarchivedRateListSet.first(where: { $0.date == historicalDate}) {
                        // 有既有資料可以用
                        historicalRateListSet.insert(historicalRateList)
                        print("###", self, #function, "從既有的資料中找到：", historicalDate)
                    } else {
                        // 沒有既有資料，要透過網路拿取
                        print("###", self, #function, "向伺服器拿取資料：", historicalDate)
                        
                        dispatchGroup?.enter()
                        RateListFetcher.fetchRateList(for: .historical(date: historicalDate) ) { result in
                            switch result {
                            case .success(let fetchedRateList):
                                historicalRateListSet.insert(fetchedRateList)
                                unarchivedRateListSet.insert(fetchedRateList)
                                dispatchGroup?.leave()
                            case .failure(let error):
                                completionHandler(.failure(error))
                                dispatchGroup = nil
                            }
                        }
                    }
                }
                
                // 所需的資料全部拿到後
                dispatchGroup?.notify(queue: .main) {
                    print("###", self, #function, "全部的資料是\n\t", historicalRateListSet)
                    completionHandler(.success((latestRateList, historicalRateListSet)))

                    do {
                        try RateListSetArchiver.archive(unarchivedRateListSet)
                    } catch {
                        #warning("存檔失敗不知道要幹嘛？？ 考慮改成 `try?`")
                        completionHandler(.failure(error))
                    }
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

// MARK: - Combine Part
extension RateListSetController {
    /// 獲得當下以及指定天數的歷史幣別匯率的資料
    /// - Parameter numberOfDay: 除了當下，所需歷史資料的天數
    /// - Returns: 送出所需的資料的 publisher
    static func rateListSetPublisher(forDays numberOfDay: Int)
        -> AnyPublisher<(latestRateList: ResponseDataModel.RateList, historicalRateListSet: Set<ResponseDataModel.RateList>), Error> {
        
        return RateListFetcher.rateListPublisher(for: .latest)
            .combineLatest(RateListSetArchiver.unarchivedRateListSetPublisher())
            .flatMap { (latestRateList, unarchivedRateListSet) -> AnyPublisher<(latestRateList: ResponseDataModel.RateList, historicalRateListSet: Set<ResponseDataModel.RateList>), Error> in
                
                /// 在日期範圍內，需要向伺服器拿的資料
                var needToFetchRateListPublisherArray = Array<AnyPublisher<ResponseDataModel.RateList, Error>>()
                
                /// 在日期範圍內，從硬碟中讀出來的資料
                var historicalRateListNeededSet = Set<ResponseDataModel.RateList>()
                
                for numberOfDayAgo in 1...numberOfDay {
                    let historicalDate = latestRateList.date.advanced(by: 24 * 60 * 60 * Double(-numberOfDayAgo))
                    
                    if let historicalRateList = unarchivedRateListSet.first(where: { $0.date == historicalDate}) {
                        historicalRateListNeededSet.insert(historicalRateList)
                    } else {
                        needToFetchRateListPublisherArray.append(RateListFetcher.rateListPublisher(for: .historical(date: historicalDate)))
                    }
                }
                
                #warning("下面這個 if-else statement 很不漂亮，想要用 reactive 串起來")
                if needToFetchRateListPublisherArray.isEmpty {
                    return Just((latestRateList, historicalRateListNeededSet))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    // 當能夠在歷史資料中，找到全部所需的資料時，publisher array 會是空的，此時 merge many 不會送出值。
                    return Publishers.MergeMany(needToFetchRateListPublisherArray)
                        .collect(numberOfDay)
                        .tryMap { fetchRateListArray -> Array<ResponseDataModel.RateList> in
                            let rateListSet = Set(fetchRateListArray).union(unarchivedRateListSet)
                            try RateListSetArchiver.archive(rateListSet)
                            return fetchRateListArray
                        }
                        .map { Set($0).union(historicalRateListNeededSet)}
                        .map { (latestRateList, $0)}
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
