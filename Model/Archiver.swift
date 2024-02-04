import Foundation

protocol ArchiverProtocol {
    static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws
    
    static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate
    
    static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool
    
    static func removeAllStoredFile() throws
}

/// 讀寫 Historical Rate 的類別
enum Archiver {}

extension Archiver: ArchiverProtocol {
    /// 寫入資料
    /// - Parameter historicalRate: 要寫入的資料
    static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws {
        let data: Data = try jsonEncoder.encode(historicalRate)
        let url: URL = documentsDirectory.appending(path: historicalRate.dateString)
            .appendingPathExtension(jsonPathExtension)
        try data.write(to: url)
        
        print("###", self, #function, "寫入資料:\n\t", historicalRate)
    }
    
    /// 讀取資料
    /// - Parameter fileName: historical rate 的日期，也是檔案名稱
    /// - Returns: historical rate
    static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
        let url: URL = documentsDirectory.appending(path: fileName)
            .appendingPathExtension(jsonPathExtension)
        
        do {
            let data: Data = try Data(contentsOf: url)
            
            AppUtility.prettyPrint(data)
            
            let historicalRate: ResponseDataModel.HistoricalRate = try jsonDecoder.decode(ResponseDataModel.HistoricalRate.self, from: data)
        
            print("###", self, #function, "讀取資料:\n\t", historicalRate)
            
            return historicalRate
        }
        catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }
    
    /// 查看某 historical rate 是否存於本地
    /// - Parameter fileName: historical rate 的日期字串
    /// - Returns: historical rate 是否存於本地
    static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool {
        let fileURL: URL = documentsDirectory.appending(path: fileName)
            .appendingPathExtension(jsonPathExtension)
        
        return FileManager.default.fileExists(atPath: fileURL.path())
    }
    
    /// 移除全部存於本地的檔案
    static func removeAllStoredFile() throws {
        try FileManager.default
            .contentsOfDirectory(at: documentsDirectory,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)
            .filter { fileURL in fileURL.pathExtension == jsonPathExtension }
            .forEach { fileURL in try FileManager.default.removeItem(at: fileURL) }
    }
}

private extension Archiver {
    /// app 的路徑
    static let documentsDirectory: URL = URL.documentsDirectory
    
    /// 共用的 decoder
    static let jsonDecoder: JSONDecoder = ResponseDataModel.jsonDecoder
    
    /// 共用的 encoder
    static let jsonEncoder: JSONEncoder = ResponseDataModel.jsonEncoder
    
    /// 儲存的檔案的副檔名
    static let jsonPathExtension: String = "json"
}
