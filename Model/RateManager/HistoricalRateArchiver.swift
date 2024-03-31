import Foundation

/// 讀寫 Historical Rate 的類別，當使用的 file manager 是 `.default`，這個 class 是 thread safe
class HistoricalRateArchiver {
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
    private let nextHistoricalRateProvider: HistoricalRateProviderProtocol
    
    private let documentsDirectory: URL
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let jsonPathExtension: String
}

// MARK: - static property
extension HistoricalRateArchiver {
    static let shared: HistoricalRateArchiver = HistoricalRateArchiver()
}

// MARK: - private instance methods
private extension HistoricalRateArchiver {
    /// 寫入資料
    /// - Parameter historicalRate: 要寫入的資料
    func archive(historicalRate: ResponseDataModel.HistoricalRate) throws {
        let data: Data = try jsonEncoder.encode(historicalRate)
        let url: URL = documentsDirectory.appending(path: historicalRate.dateString)
            .appendingPathExtension(jsonPathExtension)
        try data.write(to: url)
        
        print("###", self, #function, "寫入資料:\n\t", historicalRate)
    }
    
    /// 讀取資料
    /// - Parameter fileName: historical rate 的日期，也是檔案名稱
    /// - Returns: historical rate
    func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
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
            try? fileManager.removeItem(at: url)
            throw error
        }
    }
    
    /// 查看某 historical rate 是否存於本地
    /// - Parameter fileName: historical rate 的日期字串
    /// - Returns: historical rate 是否存於本地
    func hasFileInDisk(historicalRateDateString fileName: String) -> Bool {
        let fileURL: URL = documentsDirectory.appending(path: fileName)
            .appendingPathExtension(jsonPathExtension)
        
        return fileManager.fileExists(atPath: fileURL.path())
    }
    
    /// 移除全部存於本地的檔案
    func removeAllStoredFile() throws {
        try fileManager
            .contentsOfDirectory(at: documentsDirectory,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)
            .filter { fileURL in fileURL.pathExtension == jsonPathExtension }
            .forEach { fileURL in try fileManager.removeItem(at: fileURL) }
    }
}

// MARK: - conforms to HistoricalRateProviderProtocol
extension HistoricalRateArchiver: HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           historicalRateResultHandler: @escaping HistoricalRateResultHandler) {
        if hasFileInDisk(historicalRateDateString: dateString) {
            do {
                let unarchivedHistoricalRate: ResponseDataModel.HistoricalRate = try unarchive(historicalRateDateString: dateString)
                historicalRateResultHandler(.success(unarchivedHistoricalRate))
            }
            catch {
                nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { result in
                    if let fetchedHistoricalRate = try? result.get() {
                        DispatchQueue.global().async { [unowned self] in
                            try? archive(historicalRate: fetchedHistoricalRate)
                        }
                    }
                    
                    historicalRateResultHandler(result)
                }
            }
        }
        else {
            nextHistoricalRateProvider.historicalRateFor(dateString: dateString) { result in
                if let fetchedHistoricalRate = try? result.get() {
                    DispatchQueue.global().async { [unowned self] in
                        try? archive(historicalRate: fetchedHistoricalRate)
                    }
                }
                
                historicalRateResultHandler(result)
            }
        }
    }
}
