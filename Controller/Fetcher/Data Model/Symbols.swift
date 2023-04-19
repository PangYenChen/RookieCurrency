//
//  Symbols.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/4/18.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension ResponseDataModel {
    struct Symbols: Decodable {
        let symbols: [ResponseDataModel.CurrencyCode: String]
    }
}
