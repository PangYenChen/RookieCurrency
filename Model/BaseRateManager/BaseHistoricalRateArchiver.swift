import Foundation

/// 讀寫 Historical Rate 的類別，當使用的 file manager 是 `.default`，這個 class 是 thread safe
class BaseHistoricalRateArchiver {
    // MARK: - initializer
    init(fileManager: FileManager = .default,
         nextHistoricalRateProvider: HistoricalRateProviderProtocol = Fetcher.shared) {
        self.fileManager = fileManager
        self.nextHistoricalRateProvider = nextHistoricalRateProvider
        
        documentsDirectory = URL.documentsDirectory
        jsonDecoder = ResponseDataModel.jsonDecoder
        jsonEncoder = ResponseDataModel.jsonEncoder
        jsonPathExtension = "json"
    }
    
    // MARK: - private property
    // MARK: dependencies
    private let fileManager: FileManager
    let nextHistoricalRateProvider: HistoricalRateProviderProtocol
    
    private let documentsDirectory: URL
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let jsonPathExtension: String
}

// MARK: - static property
extension HistoricalRateArchiver {
    static let shared: HistoricalRateArchiver = HistoricalRateArchiver()
}

// MARK: - instance methods
extension BaseHistoricalRateArchiver {
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

extension BaseHistoricalRateArchiver: BaseHistoricalRateProviderProtocol {
    func removeCachedAndStoredRate() {
        try? fileManager
            .contentsOfDirectory(at: documentsDirectory,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)
            .filter { fileURL in fileURL.pathExtension == jsonPathExtension }
            .forEach { fileURL in try fileManager.removeItem(at: fileURL) }
        
        nextHistoricalRateProvider.removeCachedAndStoredRate()
    }
}
