import Foundation
import UniformTypeIdentifiers
import OSLog

/// 讀寫 Historical Rate 的類別，當使用的 file manager 是 `.default`，這個 class 是 thread safe
class HistoricalRateArchiver {
    init(fileManager: FileManager, serialDispatchQueue: DispatchQueue = DispatchQueue(label: "historical.rate.archiver")) {
        self.fileManager = fileManager
        
        documentsDirectory = URL.documentsDirectory
        jsonDecoder = ResponseDataModel.jsonDecoder
        jsonEncoder = ResponseDataModel.jsonEncoder
        jsonType = UTType.json
        
        logger = LoggerFactory.make(category: String(describing: Self.self))
        
        self.serialDispatchQueue = serialDispatchQueue
    }
    
    private let fileManager: FileManager
    
    private let documentsDirectory: URL
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let jsonType: UTType
    
    private let logger: Logger
    
    private let serialDispatchQueue: DispatchQueue
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
    var description: String { String(describing: Self.self) }
    
    func readFor(dateString: String) -> ResponseDataModel.HistoricalRate? {
        let fileURL: URL = fileURLWith(fileName: dateString)
        
        guard fileManager.fileExists(atPath: fileURL.path()) else {
            logger.debug("return nil for date: \(dateString)")
            
            return nil
        }
        
        do {
            let data: Data = try Data(contentsOf: fileURL)
            
            let rate: ResponseDataModel.HistoricalRate = try jsonDecoder.decode(ResponseDataModel.HistoricalRate.self, from: data)
            logger.debug("return a historical rate for date: \(dateString)")
            
            return rate
        }
        catch {
            try? fileManager.removeItem(at: fileURL)
            logger.debug("return nil for date: \(dateString), error: \(error)")
            
            return nil
        }
    }
    
    func store(_ rate: ResponseDataModel.HistoricalRate) {
        serialDispatchQueue.async { [weak self] in
            guard let self else { return }
            
            do {
                let data: Data = try jsonEncoder.encode(rate)
                let fileURL: URL = fileURLWith(fileName: rate.dateString)
                
                try data.write(to: fileURL)
                
                logger.debug("store historical rate for date: \(rate.dateString)")
            }
            catch {
                logger.debug("fail to store historical rate for date: \(rate.dateString), error: \(error)")
            }
        }
    }
    
    func removeAll() {
        serialDispatchQueue.async { [weak self] in
            guard let self else { return }
            
            do {
                try fileManager
                    .contentsOfDirectory(at: documentsDirectory,
                                         includingPropertiesForKeys: nil,
                                         options: .skipsHiddenFiles)
                    .filter { fileURL in fileURL.pathExtension == self.jsonType.preferredFilenameExtension }
                    .forEach { fileURL in try self.fileManager.removeItem(at: fileURL) }
                
                logger.debug("remove all stored historical rate")
            }
            catch { logger.debug("fail to remove all stored historical rate") }
        }
    }
}
