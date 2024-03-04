import Foundation

final class ResultModel: BaseResultModel {
    // MARK: - life cycle
    init(rateManager: RateManagerProtocol = RateManager.shared,
         userSettingManager: UserSettingManagerProtocol = UserSettingManager.shared,
         timer: TimerProtocol = TimerProxy()) {
        self.rateManager = rateManager
        self.userSettingManager = userSettingManager
        
        setting = (numberOfDays: userSettingManager.numberOfDays,
                   baseCurrencyCode: userSettingManager.baseCurrencyCode,
                   currencyCodeOfInterest: userSettingManager.currencyCodeOfInterest)
        
        order = userSettingManager.resultOrder
        
        searchText = nil
        analysisSuccesses = []
        
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
    
    /// 是 user setting 的一部份，要傳遞到 setting model 的資料，在那邊編輯
    private var setting: Setting
    
    /// 是 user setting 的一部份，跟 `setting` 不同的是，`order` 在這裡修改
    private var order: Order
    
    private var searchText: String?
    
    private var latestUpdateTimestamp: Int?
    
    private var analysisSuccesses: Set<Analysis.Success>
    
    var sortedAnalysisSuccessesHandler: SortedAnalysisSuccessesHandlebar?
    
    var refreshStatusHandler: RefreshStatusHandlebar?
    
    var errorHandler: ErrorHandler?
}

// MARK: - methods
extension ResultModel {
    func refresh() {
        refreshStatusHandler?(.process)
        
        rateManager.getRateFor(numberOfDays: setting.numberOfDays, completionHandlerQueue: .main) { [unowned self] result in
            switch result {
                case .success(let (latestRate, historicalRateSet)):
                    let analysis: Analysis = Self.analyze(baseCurrencyCode: setting.baseCurrencyCode,
                                                          currencyCodeOfInterest: setting.currencyCodeOfInterest,
                                                          latestRate: latestRate,
                                                          historicalRateSet: historicalRateSet)
                    
                    guard analysis.dataAbsentCurrencyCodeSet.isEmpty else {
                        // TODO: 還沒處理錯誤"
                        assertionFailure("還沒處理錯誤")
                        return
                    }
                    
                    analysisSuccesses = analysis.successes
                    
                    let sortedAnalysisSuccesses: [Analysis.Success] = Self.sort(self.analysisSuccesses,
                                                                                by: self.order,
                                                                                filteredIfNeededBy: self.searchText)
                    sortedAnalysisSuccessesHandler?(sortedAnalysisSuccesses)
                    
                    latestUpdateTimestamp = latestRate.timestamp
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestRate.timestamp))
                    
                case .failure(let error):
                    errorHandler?(error)
                    
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestUpdateTimestamp))
            }
        }
    }
    
    // TODO: 名字要想一下，這看不出來有 return value
    func setOrder(_ order: BaseResultModel.Order) -> [BaseResultModel.Analysis.Success] {
        userSettingManager.resultOrder = order
        self.order = order
        
        return Self.sort(self.analysisSuccesses,
                         by: self.order,
                         filteredIfNeededBy: self.searchText)
    }
    
    // TODO: 名字要想一下，這看不出來有 return value
    func setSearchText(_ searchText: String?) -> [BaseResultModel.Analysis.Success] {
        self.searchText = searchText
        
        return Self.sort(self.analysisSuccesses,
                         by: self.order,
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
        
        return SettingModel(setting: setting) { [unowned self] setting in
            self.setting = setting
            
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
    typealias SortedAnalysisSuccessesHandlebar = (_ sortedAnalysisSuccesses: [BaseResultModel.Analysis.Success]) -> Void
    
    typealias RefreshStatusHandlebar = (_ refreshStatus: BaseResultModel.RefreshStatus) -> Void
    
    typealias ErrorHandler = (_ error: Error) -> Void
}
