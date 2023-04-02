//
//  RateController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

/// 用來獲得各幣別匯率資料的類別
class RateController {
    static let shared: RateController = .init()
    
    let fetcher: FetcherProtocol
    
    init(fetcher: FetcherProtocol = Fetcher.shared) {
        self.fetcher = fetcher
    }
    
    func requestDateStringForHistoricalRate(numberOfDaysAgo: Int, from start: Date = .now) -> String? {
        Calendar(identifier: .gregorian) // server calendar
            .date(byAdding: .day, value: -numberOfDaysAgo, to: start)
            .map { historicalDate in AppUtility.requestDateFormatter.string(from: historicalDate) }
    }

}
