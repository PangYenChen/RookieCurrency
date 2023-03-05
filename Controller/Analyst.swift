//
//  Analyst.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 從數據中分析出幣別的升貶值的物件
enum Analyst {
    
    /// <#Description#>
    /// - Parameters:
    ///   - latestRate: <#latestRate description#>
    ///   - historicalRateSet: <#historicalRateSet description#>
    ///   - baseCurrency: <#baseCurrency description#>
    static func analyze(latestRate: ResponseDataModel.LatestRate,
                        historicalRateSet: Set<ResponseDataModel.HistoricalRate>,
                        baseCurrency: Currency)
    -> [Currency: (latest: Double, mean: Double, deviation: Double)] {
        
        var result = [Currency: (latest: Double, mean: Double, deviation: Double)]()
        
        for currency in Currency.allCases {
            for historicalRate in historicalRateSet {
                // 基準幣別的換算
                result[currency, default: (latest: 0, mean: 0, deviation: 0)].mean += historicalRate[baseCurrency]! / historicalRate[currency]!
            }
            result[currency]!.mean /= Double(historicalRateSet.count)
            result[currency]!.latest = latestRate[baseCurrency]! / latestRate[currency]!
            result[currency]!.deviation = (latestRate[baseCurrency]! / latestRate[currency]! - result[currency]!.mean) / result[currency]!.mean
        }
        
        result.removeValue(forKey: baseCurrency)
        
        return result
    }
}















