//
//  Historical.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/28.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension Endpoint {
    struct Historical: BaseOnTWD {
        typealias ResponseType = ResponseDataModel.HistoricalRate
        
        let partialPath: String
        
#warning("考慮直接輸入日期字串")
        init(date: Date) {
            self.partialPath = AppSetting.requestDateFormatter.string(from: date)
        }
    }
}
