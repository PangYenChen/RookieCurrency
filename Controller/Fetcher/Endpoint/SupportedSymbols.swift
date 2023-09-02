//
//  SupportedSymbols.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/4/17.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

extension Endpoints {
    struct SupportedSymbols: PartialPathProvider {
        typealias ResponseType = ResponseDataModel.SupportedSymbols
        
        let partialPath: String = "symbols"
    }
}
