import Foundation

/// 讀寫 Historical Rate 的類別，當使用的 file manager 是 `.default`，這個 class 是 thread safe
class HistoricalRateArchiver {
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        
        documentsDirectory = URL.documentsDirectory
        jsonDecoder = ResponseDataModel.jsonDecoder
        jsonEncoder = ResponseDataModel.jsonEncoder
        jsonPathExtension = "json"
    }
    
    private let fileManager: FileManager
    
    private let documentsDirectory: URL
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let jsonPathExtension: String
}

// MARK: - instance methods
extension HistoricalRateArchiver {
    /// 寫入資料
    /// - Parameter historicalRate: 要寫入的資料
    func archive(_ rate: ResponseDataModel.HistoricalRate) throws {
        let data: Data = try jsonEncoder.encode(rate)
        let url: URL = documentsDirectory.appending(path: rate.dateString)
            .appendingPathExtension(jsonPathExtension)
        try data.write(to: url)
        
        print("###", self, #function, "寫入資料:\n\t", rate)
    }
    
    /// 讀取資料
    /// - Parameter fileName: historical rate 的日期，也是檔案名稱
    /// - Returns: historical rate
    func unarchiveRateWith(dateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
        let url: URL = documentsDirectory.appending(path: fileName)
            .appendingPathExtension(jsonPathExtension)
        
        do {
            let data: Data = try Data(contentsOf: url)
            
            AppUtility.prettyPrint(data)
            
            let rate: ResponseDataModel.HistoricalRate = try jsonDecoder.decode(ResponseDataModel.HistoricalRate.self, from: data)
            
            print("###", self, #function, "讀取資料:\n\t", rate)
            
            return rate
        }
        catch {
            try? fileManager.removeItem(at: url)
            throw error
        }
    }
    
    /// 查看某 historical rate 是否存於本地
    /// - Parameter fileName: historical rate 的日期字串
    /// - Returns: historical rate 是否存於本地
    func hasFileInDiskWith(dateString fileName: String) -> Bool {
        let fileURL: URL = documentsDirectory.appending(path: fileName)
            .appendingPathExtension(jsonPathExtension)
        
        return fileManager.fileExists(atPath: fileURL.path())
    }
}

extension HistoricalRateArchiver: HistoricalRateStorageProtocol {
    func readFor(dateString: String) -> ResponseDataModel.HistoricalRate? {
        guard hasFileInDiskWith(dateString: dateString) else { return nil }
        return try? unarchiveRateWith(dateString: dateString)
    }
    
    func store(_ rate: ResponseDataModel.HistoricalRate) {
        try? archive(rate)
    }
    
    func removeCachedAndStoredRate() {
        try? fileManager
            .contentsOfDirectory(at: documentsDirectory,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)
            .filter { fileURL in fileURL.pathExtension == jsonPathExtension }
            .forEach { fileURL in try fileManager.removeItem(at: fileURL) }
    }
}
