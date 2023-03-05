//
//  Archiver.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/5.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

/// 讀寫 RateListSet 的類別
enum Archiver {
    /// app 的路徑
    private static let documentsDirectory = URL.documentsDirectory
    
    /// 存放資料的路徑
    private static let archiveURL = documentsDirectory.appendingPathComponent("rateListSet.json")
    
    /// 共用的 decoder
    private static let jsonDecoder = JSONDecoder()
    
    /// 共用的 encoder
    private static let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }()
}

extension Archiver {
    
    /// 讀取先前存放的資料
    static func unarchive() throws -> Set<ResponseDataModel.HistoricalRate> {
        
        guard FileManager.default.fileExists(atPath: archiveURL.path) else { return [] }
        
        let data = try Data(contentsOf: archiveURL)
        let rateListSet = try jsonDecoder.decode(Set<ResponseDataModel.HistoricalRate>.self, from: data)
        
        print("###", self, #function, "讀取資料:\n\t", rateListSet)
        return rateListSet
    }
    
    /// 寫入資料
    /// - Parameter rateListSet: 要寫入的資料
    static func archive(_ historicalRateSet: Set<ResponseDataModel.HistoricalRate>) throws {
        let data = try jsonEncoder.encode(historicalRateSet)
        try data.write(to: archiveURL)
        print("###", self, #function, "寫入資料:\n\t", historicalRateSet)
    }
}

