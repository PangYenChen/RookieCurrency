//
//  RateListSetArchiver.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/5.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

/// 讀寫 RateListSet 的類別
enum RateListSetArchiver {
    /// app 的路徑
    private static let documentsDirectory =
        FileManager
            .default.urls(for: .documentDirectory,
                          in: .userDomainMask).first!
    
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

// MARK: - Imperative Part
extension RateListSetArchiver {
    /// 讀取先前存放的資料
    /// - Returns: timeout interval 為 5 秒的 data task publisher
    static func unarchive() throws -> Set<ResponseDataModel.RateList> {

        guard FileManager.default.fileExists(atPath: archiveURL.path) else { return []}
        
        let data = try Data(contentsOf: archiveURL)
        let rateListSet = try jsonDecoder.decode(Set<ResponseDataModel.RateList>.self, from: data)
        
        print("###", self, #function, "讀取資料:\n\t", rateListSet)
        return rateListSet
    }
    
    /// 寫入資料
    /// - Parameter rateListSet: 要寫入的資料
    static func archive(_ rateListSet: Set<ResponseDataModel.RateList>) throws {
        var historicalRateListSet = rateListSet.filter { $0.historical}
        // 故意移除一個項目，測試程式碼是否正常
        historicalRateListSet.removeFirst()
        let data = try jsonEncoder.encode(historicalRateListSet)
        try data.write(to: archiveURL)
        print("###", self, #function, "寫入資料:\n\t", rateListSet)
    }
}


// MARK: - Combine Part
extension RateListSetArchiver {
    /// 送出先前儲存起來的 rate list set
    /// - Returns: 送出先前儲存的 rate list 的 publisher
    static func unarchivedRateListSetPublisher() -> AnyPublisher<Set<ResponseDataModel.RateList>, Error> {
        
        return Future<Set<ResponseDataModel.RateList>, Error> { promise in
    
            guard FileManager.default.fileExists(atPath: archiveURL.path) else {
                promise(.success([]))
                return
            }
            
            do {
                let data = try Data(contentsOf: archiveURL)
                let rateListSet = try jsonDecoder.decode(Set<ResponseDataModel.RateList>.self, from: data)
                
                promise(.success(rateListSet))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
