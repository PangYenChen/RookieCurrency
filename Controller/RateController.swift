import Foundation

/// 用來獲得各貨幣匯率資料的類別
class RateController {
    static let shared: RateController = .init()
    
    let fetcher: FetcherProtocol
    
    let archiver: ArchiverProtocol.Type
    
    /// 用來
    /// - 同時讀寫 historicalRateDictionary、
    /// - archive 和 unarchive 檔案
    let concurrentQueue: DispatchQueue
    
    var historicalRateDictionary: [String: ResponseDataModel.HistoricalRate]
    
    init(fetcher: FetcherProtocol = Fetcher.shared,
         archiver: ArchiverProtocol.Type = Archiver.self,
         concurrentQueue: DispatchQueue = DispatchQueue(label: "rate controller concurrent queue", attributes: .concurrent)
         
    ) {
        self.fetcher = fetcher
        self.archiver = archiver
        self.concurrentQueue = concurrentQueue
        
        historicalRateDictionary = [:]
    }
    
    func historicalRateDateStrings(numberOfDaysAgo: Int, from start: Date) -> Set<String> {
        Set(
            (1...numberOfDaysAgo)
                .compactMap { numberOfDaysAgo in
                    Calendar(identifier: .gregorian) // server calendar
                        .date(byAdding: .day, value: -numberOfDaysAgo, to: start)
                        .map { historicalDate in AppUtility.requestDateFormatter.string(from: historicalDate) }
                }
        )
    }
    
    func removeCachedAndStoredData() {
        concurrentQueue.async(flags: .barrier) { [unowned self] in historicalRateDictionary = [:] }
        try? archiver.removeAllStoredFile()
    }
}
