import Foundation

/// 用來獲得各貨幣匯率資料的類別
class BaseRateManager {
    // MARK: - initializer
    init(fetcher: FetcherProtocol = Fetcher.shared,
         archiver: ArchiverProtocol = Archiver.shared,
         concurrentQueue: DispatchQueue = DispatchQueue(label: "rate manager concurrent queue", attributes: .concurrent)) {
        self.fetcher = fetcher
        self.archiver = archiver
        self.concurrentQueue = concurrentQueue
        
        historicalRateDictionary = [:]
    }
    
    // MARK: - instance properties
    let fetcher: FetcherProtocol
    
    let archiver: ArchiverProtocol
    
    /// 用來
    /// - 同時讀寫 historicalRateDictionary、
    /// - archive 和 unarchive 檔案
    let concurrentQueue: DispatchQueue
    
    var historicalRateDictionary: [String: ResponseDataModel.HistoricalRate]
}

// MARK: - instance method
extension BaseRateManager {
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
        concurrentQueue.async(qos: .background, flags: .barrier) { [unowned self] in historicalRateDictionary = [:] }
        try? archiver.removeAllStoredFile()
    }
}

// MARK: - static property
extension BaseRateManager {
    static let shared: RateManager = .init()
}

// MARK: - name space
extension BaseRateManager {
    typealias RateTuple = (latestRate: ResponseDataModel.LatestRate,
                           historicalRateSet: Set<ResponseDataModel.HistoricalRate>)
}
