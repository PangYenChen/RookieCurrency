import Foundation
import UniformTypeIdentifiers

/// 讀寫 Historical Rate 的類別，當使用的 file manager 是 `.default`，這個 class 是 thread safe
class HistoricalRateArchiver {
    init(fileManager: FileManager) {
        self.fileManager = fileManager
        
        documentsDirectory = URL.documentsDirectory
        jsonDecoder = ResponseDataModel.jsonDecoder
        jsonEncoder = ResponseDataModel.jsonEncoder
        jsonType = UTType.json
    }
    
    private let fileManager: FileManager
    
    private let documentsDirectory: URL
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let jsonType: UTType
}

// MARK: - instance methods
extension HistoricalRateArchiver {
    private func fileURLWith(fileName: String) -> URL {
        documentsDirectory
            .appending(path: fileName)
            .appendingPathExtension(for: jsonType)
    }
}

extension HistoricalRateArchiver: HistoricalRateStorageProtocol {
    func readFor(dateString: String) -> ResponseDataModel.HistoricalRate? {
        let fileURL: URL = fileURLWith(fileName: dateString)
        
        guard fileManager.fileExists(atPath: fileURL.path()) else { return nil }
        
        do {
            let data: Data = try Data(contentsOf: fileURL)
            
            let rate: ResponseDataModel.HistoricalRate = try jsonDecoder.decode(ResponseDataModel.HistoricalRate.self, from: data)
            
            print("###", self, #function, "讀取資料:\n\t", rate)
            
            return rate
        }
        catch {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    func store(_ rate: ResponseDataModel.HistoricalRate) {
        do {
            let data: Data = try jsonEncoder.encode(rate)
            let fileURL: URL = fileURLWith(fileName: rate.dateString)
            
            try data.write(to: fileURL)
            
            print("###", self, #function, "寫入資料:\n\t", rate)
        }
        catch {
            print("###", self, #function, error)
        }
    }
    
    func removeAll() {
        try? fileManager
            .contentsOfDirectory(at: documentsDirectory,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)
            .filter { fileURL in fileURL.pathExtension == jsonType.preferredFilenameExtension }
            .forEach { fileURL in try fileManager.removeItem(at: fileURL) }
    }
}
