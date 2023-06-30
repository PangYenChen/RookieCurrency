//
//  Archiver.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/5.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

/// 讀寫 Historical Rate 的類別
enum Archiver {
    /// app 的路徑
    private static let documentsDirectory = URL.documentsDirectory
    
    /// 存放資料的路徑
    private static let archiveURL = documentsDirectory.appendingPathComponent("rateSet.json")
    
    /// 共用的 decoder
    private static let jsonDecoder = ResponseDataModel.jsonDecoder
    
    /// 共用的 encoder
    private static let jsonEncoder = ResponseDataModel.jsonEncoder
}

extension Archiver {
    
    /// 寫入資料
    /// - Parameter historicalRate: 要寫入的資料
    static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws {
        let data = try jsonEncoder.encode(historicalRate)
        let url = documentsDirectory.appendingPathComponent(historicalRate.dateString)
            .appendingPathExtension("json")
        try data.write(to: url)
        
        print("###", self, #function, "寫入資料:\n\t", historicalRate)
    }
    
    /// 讀取資料
    /// - Parameter fileName: historical rate 的日期，也是檔案名稱
    /// - Returns: historical rate
    static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
        let url = documentsDirectory.appending(component: fileName)
            .appendingPathExtension("json")
        let data: Data
        
        do {
            data = try Data(contentsOf: url)
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
        
        AppUtility.prettyPrint(data)
        
        let historicalRate: ResponseDataModel.HistoricalRate
        
        do {
            historicalRate = try jsonDecoder.decode(ResponseDataModel.HistoricalRate.self, from: data)
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
        
        print("###", self, #function, "讀取資料:\n\t", historicalRate)
        
        return historicalRate
    }
    
    
    static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
            .appendingPathExtension("json")
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}

protocol ArchiverProtocol {
    static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws
        
    static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate
    
    static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool
}

extension Archiver: ArchiverProtocol {}
