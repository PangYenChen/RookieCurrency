import Foundation
import OSLog

/// 用來獲得各貨幣匯率資料的類別
class BaseRateManager {
    init(historicalRateProvider: HistoricalRateProviderProtocol,
         latestRateProvider: LatestRateProviderProtocol) {
        self.historicalRateProvider = historicalRateProvider
        self.latestRateProvider = latestRateProvider
        venderCalendar = AppUtility.venderCalendar
        logger = LoggerFactory.make(category: String(describing: RateManager.self))
    }
    
    // MARK: - dependencies
    let historicalRateProvider: HistoricalRateProviderProtocol
    let latestRateProvider: LatestRateProviderProtocol
    private let venderCalendar: Calendar
    let logger: Logger
}

// MARK: - instance method
extension BaseRateManager {
    func historicalRateDateStrings(numberOfDaysAgo: Int, from start: Date) -> Set<String> {
        Set(
            (1...numberOfDaysAgo)
                .compactMap { numberOfDaysAgo in
                    venderCalendar
                        .date(byAdding: .day, value: -numberOfDaysAgo, to: start)
                        .map { historicalDate in AppUtility.requestDateFormatter.string(from: historicalDate) }
                }
        )
    }
    
    func removeAllStorage() {
        historicalRateProvider.removeAllStorage()
    }
}

// MARK: - static property
extension RateManager {
    static let shared: RateManager = RateManager(historicalRateProvider: HistoricalRateProviderChain.shared,
                                                 latestRateProvider: Fetcher.shared)
}

// MARK: - name space
extension BaseRateManager {
    typealias RateTuple = (latestRate: ResponseDataModel.LatestRate,
                           historicalRateSet: Set<ResponseDataModel.HistoricalRate>)
}
