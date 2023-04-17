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
                        baseCurrency: ResponseDataModel.CurrencyCode)
    -> [ResponseDataModel.CurrencyCode: (latest: Double, mean: Double, deviation: Double)] {
        
        var result = [ResponseDataModel.CurrencyCode: (latest: Double, mean: Double, deviation: Double)]()
        
        for currencyCode in Currency.allCases.map { $0.rawValue } {
            for historicalRate in historicalRateSet {
                // 基準幣別的換算
                result[currencyCode, default: (latest: 0, mean: 0, deviation: 0)].mean += historicalRate[currencyCode: baseCurrency]! / historicalRate[currencyCode: currencyCode]!
            }
            result[currencyCode]!.mean /= Double(historicalRateSet.count)
            
            
            
            
            
            result[currencyCode]!.latest = latestRate[currencyCode: baseCurrency]! / latestRate[currencyCode: currencyCode]!
            result[currencyCode]!.deviation = (latestRate[currencyCode: baseCurrency]! / latestRate[currencyCode: currencyCode]! - result[currencyCode]!.mean) / result[currencyCode]!.mean
        }
        
        result.removeValue(forKey: baseCurrency)
        
        return result
    }
}















