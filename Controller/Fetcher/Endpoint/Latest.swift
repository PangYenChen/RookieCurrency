//
//  Latest.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/28.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension Endpoint {
    struct Latest: BaseOnTWD {
        typealias ResponseType = ResponseDataModel.LatestRate
        
        let partialPath: String = "latest"
    }
}
