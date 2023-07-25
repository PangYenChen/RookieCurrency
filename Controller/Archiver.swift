//
//  Archiver.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/5.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import Foundation

/// 讀寫 Historical Rate 的類別
enum Archiver {
    /// app 的路徑
    private static let documentsDirectory = URL.documentsDirectory
    
    /// 共用的 decoder
    private static let jsonDecoder = ResponseDataModel.jsonDecoder
    
    /// 共用的 encoder
    private static let jsonEncoder = ResponseDataModel.jsonEncoder
    
    private static let jsonPathExtension: String = "json"
}

extension Archiver {
    
    /// 寫入資料
    /// - Parameter historicalRate: 要寫入的資料
    static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws {
        let data = try jsonEncoder.encode(historicalRate)
        let url = documentsDirectory.appending(path: historicalRate.dateString)
            .appendingPathExtension(jsonPathExtension)
        try data.write(to: url)
        
        print("###", self, #function, "寫入資料:\n\t", historicalRate)
    }
    
    /// 讀取資料
    /// - Parameter fileName: historical rate 的日期，也是檔案名稱
    /// - Returns: historical rate
    static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
        let url = documentsDirectory.appending(path: fileName)
            .appendingPathExtension(jsonPathExtension)
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
        let fileURL = documentsDirectory.appending(path: fileName)
            .appendingPathExtension(jsonPathExtension)
        
        return FileManager.default.fileExists(atPath: fileURL.path())
    }
    
    static func removeAllStoredFile() throws {

        try FileManager.default
            .contentsOfDirectory(at: documentsDirectory,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)
            .filter { fileURL in fileURL.pathExtension == jsonPathExtension }
            .forEach { fileURL in try FileManager.default.removeItem(at: fileURL) }
    }
}

protocol ArchiverProtocol {
    static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws
        
    static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate
    
    static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool
    
    static func removeAllStoredFile() throws
}

extension Archiver: ArchiverProtocol {}
