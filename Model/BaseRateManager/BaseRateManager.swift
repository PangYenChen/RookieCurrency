import Foundation

/// 用來獲得各貨幣匯率資料的類別
class BaseRateManager {
    // MARK: - initializer
    init(historicalRateProvider: HistoricalRateProviderProtocol = HistoricalRateProviderChain.shared,
         latestRateProvider: LatestRateProviderProtocol = Fetcher.shared) {
        self.historicalRateProvider = historicalRateProvider
        self.latestRateProvider = latestRateProvider
    }
    
    // MARK: - instance properties
    // MARK: - dependencies
    let historicalRateProvider: HistoricalRateProviderProtocol
    let latestRateProvider: LatestRateProviderProtocol
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
        historicalRateProvider.removeCachedAndStoredRate()
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
