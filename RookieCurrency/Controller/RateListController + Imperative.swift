//
//  RateListController + Imperative.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
#warning("這裡的 method 好長 看能不能拆開")
extension RateListController {
    
    /// 獲得當下以及指定天數的歷史幣別匯率的資料
    /// - Parameters:
    ///   - numberOfDay: 除了當下，所需歷史資料的天數
    ///   - completionHandler: 拿到資料後要執行的 completion handler
    func getRateListFor(numberOfDay: Int,
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
        rateListFetcher.rateList(for: .latest) { [unowned self] result in
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
                        rateListFetcher.rateList(for: .historical(date: historicalDate) ) { result in
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
                    print("###", self, #function, "全部的資料是\n\t", historicalRateListSet.sorted { lhs, rhs in lhs.date < rhs.date })
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
