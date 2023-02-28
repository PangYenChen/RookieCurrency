//
//  Historical.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/28.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension Endpoint {
    struct Historical: PathProvider {
        typealias ResponseType = ResponseDataModel.HistoricalRate
        
        let path: String
        
        init(date: Date) {
            self.path = AppSetting.requestDateFormatter.string(from: date)
        }
    }
}
