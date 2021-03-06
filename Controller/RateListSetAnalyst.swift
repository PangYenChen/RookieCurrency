//
//  RateListSetAnalyst.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 從數據中分析出幣別的升貶值的物件
enum RateListSetAnalyst {
    /// 分析幣值的生貶值
    /// - Parameters:
    ///   - latestRateList: 當下的匯率
    ///   - historicalRateListSet: 歷史上的匯率
    ///   - baseCurrency: 1 單位的其他幣別，要用這個幣別的多少錢去買
    static func analyze(latestRateList: ResponseDataModel.RateList,
                        historicalRateListSet: Set<ResponseDataModel.RateList>,
                        baseCurrency: ResponseDataModel.RateList.Currency)
        -> Dictionary<ResponseDataModel.RateList.Currency, (latest: Double, mean: Double, deviation: Double)> {
            
            var result = Dictionary<ResponseDataModel.RateList.Currency, (latest: Double, mean: Double, deviation: Double)>()
            
            for currency in ResponseDataModel.RateList.Currency.allCases {
                for rateList in historicalRateListSet {
                    // 基準幣別的換算
                    result[currency, default: (latest: 0, mean: 0, deviation: 0)].mean += rateList[baseCurrency]! / rateList[currency]!
                }
                result[currency]!.mean /= Double(historicalRateListSet.count)
                result[currency]!.latest = latestRateList[baseCurrency]! / latestRateList[currency]!
                result[currency]!.deviation = (latestRateList[baseCurrency]! / latestRateList[currency]! - result[currency]!.mean) / result[currency]!.mean
            }
            
            result.removeValue(forKey: baseCurrency)
            
            return result
    }
}















