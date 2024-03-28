import Foundation

/// 用來獲得各貨幣匯率資料的類別
class BaseRateManager {
    // MARK: - initializer
    init(
        historicalRateProvider: HistoricalRateProviderProtocol = HistoricalRateCache.shared,
        latestRateProvider: LatestRateProviderProtocol = Fetcher.shared,
        concurrentQueue: DispatchQueue = DispatchQueue(label: "rate manager concurrent queue",
                                                       attributes: .concurrent)
    ) {
        self.historicalRateProvider = historicalRateProvider
        self.latestRateProvider = latestRateProvider
        
        self.concurrentQueue = concurrentQueue
    }
    
    // MARK: - instance properties
    // MARK: - dependencies
    let historicalRateProvider: HistoricalRateProviderProtocol
    let latestRateProvider: LatestRateProviderProtocol
    
    /// dispatch group 要用的 dispatch queue
    // TODO: 檢查下 reactive 要不要用
    // TODO: 想一下是不是用 serial queue 就好了
    let concurrentQueue: DispatchQueue
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
        // TODO: 現在的 historical rate provider 還沒有清除的機制
//        historicalRateCache.removeAll()
//        try? archiver.removeAllStoredFile()
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
