import Foundation

final class ResultModel: BaseResultModel {
    // MARK: - life cycle
    init(userSettingManager: UserSettingManagerProtocol = UserSettingManager.shared,
         rateManager: RateManagerProtocol = RateManager.shared,
         currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared,
         timer: TimerProtocol = TimerProxy()) {
        self.userSettingManager = userSettingManager
        self.rateManager = rateManager
        self.timer = timer
        
        searchText = nil
        rateStatistics = []
        
        super.init(userSettingManager: userSettingManager,
                   currencyDescriber: currencyDescriber)
        
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
    
    // MARK: - internal handlers
    var rateStatisticsHandler: RateStatisticsHandlebar?
    
    var dataAbsentCurrencyCodeSetHandler: DataAbsentCurrencyCodeSetHandler?
    
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
                        dataAbsentCurrencyCodeSetHandler?(statisticsInfo.dataAbsentCurrencyCodeSet)
                        return
                    }
                    
                    rateStatistics = statisticsInfo.rateStatistics
                    
                    let sortedRateStatistics: [RateStatistic] = Self.sort(self.rateStatistics,
                                                                          by: userSettingManager.resultOrder,
                                                                          filteredIfNeededBy: self.searchText)
                    rateStatisticsHandler?(sortedRateStatistics)
                    
                    latestUpdateTimestamp = latestRate.timestamp
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestRate.timestamp))
                    
                case .failure(let error):
                    errorHandler?(error)
                    
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestUpdateTimestamp))
            }
        }
    }
    
    func sortedRateStatistics(by order: Order) -> [RateStatistic] {
        userSettingManager.resultOrder = order

        return Self.sort(self.rateStatistics,
                         by: userSettingManager.resultOrder,
                         filteredIfNeededBy: self.searchText)
    }
    
    func filteredRateStatistics(by searchText: String?) -> [RateStatistic] {
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
        
        let setting: Setting = (numberOfDays: userSettingManager.numberOfDays,
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
    typealias RateStatisticsHandlebar = (_ sortedRateStatistics: [RateStatistic]) -> Void
    
    typealias DataAbsentCurrencyCodeSetHandler = (_ dataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>) -> Void
    
    typealias RefreshStatusHandlebar = (_ refreshStatus: RefreshStatus) -> Void
    
    typealias ErrorHandler = (_ error: Error) -> Void
}
