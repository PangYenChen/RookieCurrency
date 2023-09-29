//
//  BaseResultModel.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/9/29.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

class BaseResultModel {
    
    init() {
        
    }
    
    
    func updateData(numberOfDays: Int,
                    from start: Date = .now,
                    completionHandlerQueue: DispatchQueue = .main,
                    completionHandler: @escaping (Result<(latestRate: ResponseDataModel.LatestRate,
                                                          historicalRateSet: Set<ResponseDataModel.HistoricalRate>),
                                                  Error>) -> ()) {
        
        
        RateController.shared.getRateFor(numberOfDays: numberOfDays,
                                         from: start,
                                         completionHandlerQueue: .main,
                                         completionHandler: completionHandler)
        
    }
}

// MARK: - name space
extension BaseResultModel {
    /// 資料的排序方式。
    /// 因為要儲存在 UserDefaults，所以 access control 不能是 private。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedName: String {
            switch self {
            case .increasing: return R.string.resultScene.increasing()
            case .decreasing: return R.string.resultScene.decreasing()
            }
        }
    }
    
    typealias UserSetting = (numberOfDay: Int, baseCurrency: ResponseDataModel.CurrencyCode, currencyOfInterest: Set<ResponseDataModel.CurrencyCode>)
}
