//
//  RateController + Imperative.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
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
            completionHandler(.failure(error))
            print("###", self, #function, "從硬碟讀取資料失敗", error)
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
                    let date = AppSetting.requestDateFormatter.date(from: latestRate.dateString)!
                    let historicalDate = date.advanced(by: 24 * 60 * 60 * Double(-numberOfDayAgo))
                    let historicalDateString = AppSetting.requestDateFormatter.string(from: historicalDate)
                    
                    
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
                                completionHandler(.failure(error))
                                dispatchGroup = nil
                            }
                        }
                    }
                }
                
                // 所需的資料全部拿到後
                dispatchGroup?.notify(queue: queue) {
                    print("###", self, #function, "全部的資料是\n\t", historicalRateSet)
                    #warning("看排序要在哪做，印出比較漂亮好debug的東西")
//                        .sorted { lhs, rhs in lhs.date < rhs.date })
                          
                    completionHandler(.success((latestRate, historicalRateSet)))
                    
                    do {
                        try Archiver.archive(unarchivedRateSet)
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
