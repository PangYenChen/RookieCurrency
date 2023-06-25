//
//  Response Data Model.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/5/21.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 這是一個命名空間，容納服務商回傳的資料所對應到的資料結構
enum ResponseDataModel {}

// MARK: - JSONDecoder and JSONEncoder
extension ResponseDataModel {
    static let jsonDecoder = JSONDecoder()
    
    static let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }()
}
