import Foundation

final class ResultModel: BaseResultModel {
    // MARK: - life cycle
    init(rateManager: RateManagerProtocol = RateManager.shared,
         userSettingManager: UserSettingManagerProtocol = UserSettingManager.shared,
         timer: TimerProtocol = TimerProxy()) {
        self.rateManager = rateManager
        self.userSettingManager = userSettingManager
        
        searchText = nil
        rateStatistics = []
        
        self.timer = timer
        
        super.init(userSettingManager: userSettingManager)
        
        resumeAutoRefreshing()
    }
    
    deinit {
        suspendAutoRefreshing()
    }
    
    // MARK: - dependencies
    private var userSettingManager: UserSettingManagerProtocol
    
    private let rateManager: RateManagerProtocol
    
    private let timer: TimerProtocol
    
    // MARK: - private properties
    private var searchText: String?
    
    private var latestUpdateTimestamp: Int?
    
    private var rateStatistics: Set<RateStatistic>
    
    var sortedRateStatisticsHandler: SortedRateStatisticsHandlebar?
    
    var refreshStatusHandler: RefreshStatusHandlebar?
    
    var errorHandler: ErrorHandler?
}

// MARK: - methods
extension ResultModel {
    func refresh() {
        refreshStatusHandler?(.process)
        
        rateManager.getRateFor(numberOfDays: userSettingManager.numberOfDays,
                               completionHandlerQueue: .main) { [unowned self] result in
            switch result {
                case .success(let (latestRate, historicalRateSet)):
                    let statisticsInfo: StatisticsInfo = Self
                        .statisticize(baseCurrencyCode: userSettingManager.baseCurrencyCode,
                                      currencyCodeOfInterest: userSettingManager.currencyCodeOfInterest,
                                      latestRate: latestRate,
                                      historicalRateSet: historicalRateSet)
                    
                    guard statisticsInfo.dataAbsentCurrencyCodeSet.isEmpty else {
                        // TODO: 還沒處理錯誤"
                        assertionFailure("還沒處理錯誤")
                        return
                    }
                    
                    rateStatistics = statisticsInfo.rateStatistics
                    
                    let sortedRateStatistics: [RateStatistic] = Self.sort(self.rateStatistics,
                                                                          by: userSettingManager.resultOrder,
                                                                          filteredIfNeededBy: self.searchText)
                    sortedRateStatisticsHandler?(sortedRateStatistics)
                    
                    latestUpdateTimestamp = latestRate.timestamp
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestRate.timestamp))
                    
                case .failure(let error):
                    errorHandler?(error)
                    
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestUpdateTimestamp))
            }
        }
    }
    
    // TODO: 名字要想一下，這看不出來有 return value
    func setOrder(_ order: Order) -> [RateStatistic] {
        userSettingManager.resultOrder = order

        return Self.sort(self.rateStatistics,
                         by: userSettingManager.resultOrder,
                         filteredIfNeededBy: self.searchText)
    }
    
    // TODO: 名字要想一下，這看不出來有 return value
    func setSearchText(_ searchText: String?) -> [RateStatistic] {
        self.searchText = searchText
        
        return Self.sort(self.rateStatistics,
                         by: self.initialOrder,
                         filteredIfNeededBy: self.searchText)
    }
}

// MARK: - private methods: auto refreshing
private extension ResultModel {
    func resumeAutoRefreshing() {
        timer.scheduledTimer(withTimeInterval: Self.autoRefreshTimeInterval) { [unowned self]  in refresh() }
    }
    
    func suspendAutoRefreshing() {
        timer.invalidate()
    }
}

// MARK: - SettingModelFactory
extension ResultModel {
    func makeSettingModel() -> SettingModel {
        suspendAutoRefreshing()
        
        let setting = (numberOfDays: userSettingManager.numberOfDays,
                       baseCurrencyCode: userSettingManager.baseCurrencyCode,
                       currencyCodeOfInterest: userSettingManager.currencyCodeOfInterest)
        
        return SettingModel(setting: setting) { [unowned self] setting in
            userSettingManager.numberOfDays = setting.numberOfDays
            userSettingManager.baseCurrencyCode = setting.baseCurrencyCode
            userSettingManager.currencyCodeOfInterest = setting.currencyCodeOfInterest
            
            resumeAutoRefreshing()
        } cancelCompletionHandler: { [unowned self] in
            resumeAutoRefreshing()
        }
    }
}

// MARK: - name space
extension ResultModel {
    typealias SortedRateStatisticsHandlebar = (_ sortedRateStatistics: [RateStatistic]) -> Void
    
    typealias RefreshStatusHandlebar = (_ refreshStatus: RefreshStatus) -> Void
    
    typealias ErrorHandler = (_ error: Error) -> Void
}
