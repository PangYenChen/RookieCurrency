import Foundation

final class ResultModel: BaseResultModel {
    // MARK: - life cycle
    init(currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared,
         rateManager: RateManagerProtocol = RateManager.shared,
         userSettingManager: UserSettingManagerProtocol = UserSettingManager.shared) {
        self.analyzedDataSorter = AnalyzedDataSorter(currencyDescriber: currencyDescriber)
        self.rateManager = rateManager
        self.userSettingManager = userSettingManager
        
        setting = (numberOfDays: userSettingManager.numberOfDays,
                   baseCurrencyCode: userSettingManager.baseCurrencyCode,
                   currencyCodeOfInterest: userSettingManager.currencyCodeOfInterest)
        
        order = userSettingManager.resultOrder
        
        searchText = nil
        analyzedDataArray = []
        
        timer = nil
        
        super.init(currencyDescriber: currencyDescriber,
                   userSettingManager: userSettingManager)
        
        resumeAutoRefreshing()
    }
    
    deinit {
        suspendAutoRefreshing()
    }
    
    // MARK: - dependencies
    private var userSettingManager: UserSettingManagerProtocol
    
    private let rateManager: RateManagerProtocol
    
    private let analyzedDataSorter: BaseResultModel.AnalyzedDataSorter
    
    // MARK: - private properties
    
    /// 是 user setting 的一部份，要傳遞到 setting scene 的資料，在那邊編輯
    private var setting: Setting
    
    /// 是 user setting 的一部份，跟 `setting` 不同的是，`order` 在這個 scene 修改
    private var order: Order
    
    private var searchText: String?
    
    private var latestUpdateTimestamp: Int?
    
    private var analyzedDataArray: [AnalyzedData]
    
    var analyzedDataArrayHandler: AnalyzedDataArrayHandlebar?
    
    var refreshStatusHandler: RefreshStatusHandlebar?
    
    var errorHandler: ErrorHandler?
    
    private var timer: Timer?
}

// MARK: - methods
extension ResultModel {
    func refresh() {
        refreshStatusHandler?(.process)
        
        rateManager.getRateFor(numberOfDays: setting.numberOfDays, completionHandlerQueue: .main) { [unowned self] result in
            switch result {
                case .success(let (latestRate, historicalRateSet)):
                    let analyzedResult: [ResponseDataModel.CurrencyCode: Result<Analyst.AnalyzedData, Analyst.AnalyzedError>] = Analyst
                        .analyze(currencyCodeOfInterest: setting.currencyCodeOfInterest,
                                 latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrencyCode: setting.baseCurrencyCode)
                    
                    let analyzedFailure: [ResponseDataModel.CurrencyCode: Result<Analyst.AnalyzedData, Analyst.AnalyzedError>] = analyzedResult
                        .filter { _, result in
                            switch result {
                                case .failure: return true
                                case .success: return false
                            }
                        }
                    
                    guard analyzedFailure.isEmpty else {
                        // TODO: 還沒處理錯誤"
                        return
                    }
                    
                    analyzedDataArray = analyzedResult
                        .compactMapValues { result in try? result.get() }
                        .map { tuple in
                            AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                        }
                    
                    let sortedAnalyzedDataArray: [BaseResultModel.AnalyzedData] = analyzedDataSorter.sort(self.analyzedDataArray,
                                                                                                          by: self.order,
                                                                                                          filteredIfNeededBy: self.searchText)
                    analyzedDataArrayHandler?(sortedAnalyzedDataArray)
                    
                    latestUpdateTimestamp = latestRate.timestamp
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestRate.timestamp))
                    
                case .failure(let error):
                    errorHandler?(error)
                    
                    refreshStatusHandler?(.idle(latestUpdateTimestamp: latestUpdateTimestamp))
            }
        }
    }
    
    // TODO: 名字要想一下，這看不出來有 return value
    func setOrder(_ order: BaseResultModel.Order) -> [BaseResultModel.AnalyzedData] {
        userSettingManager.resultOrder = order
        self.order = order
        
        return analyzedDataSorter.sort(self.analyzedDataArray,
                                       by: self.order,
                                       filteredIfNeededBy: self.searchText)
    }
    
    // TODO: 名字要想一下，這看不出來有 return value
    func setSearchText(_ searchText: String?) -> [BaseResultModel.AnalyzedData] {
        self.searchText = searchText
        
        return analyzedDataSorter.sort(self.analyzedDataArray,
                                       by: self.order,
                                       filteredIfNeededBy: self.searchText)
    }
}

// MARK: - private methods: auto refreshing
private extension ResultModel {
    func resumeAutoRefreshing() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.autoRefreshTimeInterval, repeats: true) { [unowned self] _ in
            refresh()
        }
        timer?.fire()
    }
    
    func suspendAutoRefreshing() {
        timer?.invalidate()
        timer = nil
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
    typealias AnalyzedDataArrayHandlebar = (_ analyzedData: [BaseResultModel.AnalyzedData]) -> Void
    
    typealias RefreshStatusHandlebar = (_ refreshStatus: BaseResultModel.RefreshStatus) -> Void
    
    typealias ErrorHandler = (_ error: Error) -> Void
}
