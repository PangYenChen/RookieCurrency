import Foundation

class ResultModel: BaseResultModel {
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
        analyzedSortedDataArray = []
        
        timer = nil
        
        state = .updating
        
        super.init(currencyDescriber: currencyDescriber,
                   userSettingManager: userSettingManager)
        
        resumeAutoUpdatingState()
    }
    
    // MARK: dependencies
    private var userSettingManager: UserSettingManagerProtocol
    
    private let rateManager: RateManagerProtocol
    
    private let analyzedDataSorter: BaseResultModel.AnalyzedDataSorter
    
    // MARK: - private properties
    private var setting: Setting
    
    private var order: Order
    
    private var searchText: String?
    
    private var analyzedSortedDataArray: [AnalyzedData]
    
    private var timer: Timer?
    
    private var state: State
    
    // MARK: - internal property
    var stateHandler: StateHandler? { // TODO: to be removed
        didSet {
            stateHandler?(state)
        }
    }
    
    // MARK: - hook methods
    func updateState() {
        analyzedDataFor(setting: setting)
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        userSettingManager.resultOrder = order
        self.order = order
        
        analyzedSortedDataArray = analyzedDataSorter.sort(self.analyzedSortedDataArray,
                                                          by: self.order,
                                                          filteredIfNeededBy: self.searchText)
        
        state = .sorted(analyzedSortedDataArray: analyzedSortedDataArray)
        
        stateHandler?(state)
    }
    
    override func setSearchText(_ searchText: String?) {
        self.searchText = searchText
        
        analyzedSortedDataArray = analyzedDataSorter.sort(self.analyzedSortedDataArray,
                                                          by: self.order,
                                                          filteredIfNeededBy: self.searchText)
        
        state = .sorted(analyzedSortedDataArray: analyzedSortedDataArray)
        
        stateHandler?(state)
    }
    
    override func settingModel() -> SettingModel {
        suspendAutoUpdatingState()
        
        return SettingModel(setting: setting) { [unowned self] setting in
            self.setting = setting
            
            userSettingManager.numberOfDays = setting.numberOfDays
            userSettingManager.baseCurrencyCode = setting.baseCurrencyCode
            userSettingManager.currencyCodeOfInterest = setting.currencyCodeOfInterest
            
            resumeAutoUpdatingState()
        } cancelCompletionHandler: { [unowned self] in
            resumeAutoUpdatingState()
        }
    }
}

// MARK: - private method
private extension ResultModel {
    func resumeAutoUpdatingState() {
        let autoUpdateTimeInterval: TimeInterval = 5
        timer = Timer.scheduledTimer(withTimeInterval: autoUpdateTimeInterval, repeats: true) { [unowned self] _ in
            analyzedDataFor(setting: setting)
        }
        timer?.fire()
    }
    
    func suspendAutoUpdatingState() {
        timer?.invalidate()
        timer = nil
    }
    
    func analyzedDataFor(setting: Setting) {
        stateHandler?(.updating)
        
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
                    
                    analyzedSortedDataArray = analyzedResult
                        .compactMapValues { result in try? result.get() }
                        .map { tuple in
                            AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                        }
                    
                    analyzedSortedDataArray = analyzedDataSorter.sort(self.analyzedSortedDataArray,
                                                                      by: self.order,
                                                                      filteredIfNeededBy: self.searchText)
                    
                    state = .updated(timestamp: latestRate.timestamp, analyzedSortedDataArray: analyzedSortedDataArray)
                    stateHandler?(state)
                    
                case .failure(let error):
                    state = .failure(error)
                    stateHandler?(state)
            }
        }
    }
}

// MARK: - name space
extension ResultModel {
    typealias StateHandler = (_ state: State) -> Void
}
