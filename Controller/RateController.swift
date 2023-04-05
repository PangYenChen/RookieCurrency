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
    
    let archiver: ArchiverProtocol.Type
    
    let concurrentQueue: DispatchQueue
    
    var historicalRateDictionary: [String: ResponseDataModel.HistoricalRate]
    
    init(fetcher: FetcherProtocol = Fetcher.shared, archiver: ArchiverProtocol.Type = Archiver.self) {
        self.fetcher = fetcher
        self.archiver = archiver
        
        concurrentQueue = DispatchQueue(label: "rate controller concurrent queue", attributes: .concurrent)
        
        historicalRateDictionary = [:]
    }
    
    func historicalRateDateStrings(numberOfDaysAgo: Int, from start: Date) -> Set<String> {
        Set(
            (1...numberOfDaysAgo)
                .compactMap { numberOfDaysAgo in
                    Calendar(identifier: .gregorian) // server calendar
                        .date(byAdding: .day, value: -numberOfDaysAgo, to: start)
                        .map { historicalDate in AppUtility.requestDateFormatter.string(from: historicalDate) }
                }
        )
    }

}
