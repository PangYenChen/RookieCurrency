import Foundation

class ResultModel: BaseResultModel {
    // MARK: - private properties
    private var setting: Setting
    
    private var order: Order
    
    private var searchText: String?
    
    private var analyzedSortedDataArray: [AnalyzedData]
    
    private var timer: Timer?
    
    private var state: State
    
    // MARK: - internal property
    var stateHandler: StateHandler? {
        didSet {
            stateHandler?(state)
        }
    }
    // MARK: - life cycle
    override init() {
        setting = (numberOfDays: AppUtility.numberOfDays,
                   baseCurrencyCode: AppUtility.baseCurrencyCode,
                   currencyCodeOfInterest: AppUtility.currencyCodeOfInterest)
        
        order = AppUtility.order
        
        searchText = nil
        analyzedSortedDataArray = []
        
        timer = nil
        
        state = .updating
        
        super.init()
        
        resumeAutoUpdatingState()
    }
    
    // MARK: - hook methods
    override func updateState() {
        analyzedDataFor(setting: setting)
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        AppUtility.order = order
        self.order = order
        
        analyzedSortedDataArray = Self.sort(self.analyzedSortedDataArray,
                                            by: self.order,
                                            filteredIfNeededBy: self.searchText)
        
        state = .sorted(analyzedSortedDataArray: analyzedSortedDataArray)
        
        stateHandler?(state)
    }
    
    override func setSearchText(_ searchText: String?) {
        self.searchText = searchText
        
        analyzedSortedDataArray = Self.sort(self.analyzedSortedDataArray,
                                            by: self.order,
                                            filteredIfNeededBy: self.searchText)
        
        state = .sorted(analyzedSortedDataArray: analyzedSortedDataArray)
        
        stateHandler?(state)
    }
    
    override func settingModel() -> SettingModel {
        suspendAutoUpdatingState()
        
        return SettingModel(setting: setting) { [unowned self] setting in
            self.setting = setting
            
            AppUtility.numberOfDays = setting.numberOfDays
            AppUtility.baseCurrencyCode = setting.baseCurrencyCode
            AppUtility.currencyCodeOfInterest = setting.currencyCodeOfInterest
            
            self.resumeAutoUpdatingState()
        } cancelCompletionHandler: { [unowned self] in
            self.resumeAutoUpdatingState()
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
        
        RateManager.shared.getRateFor(numberOfDays: setting.numberOfDays) { [unowned self] result in
            switch result {
            case .success(let (latestRate, historicalRateSet)):
                let analyzedResult = Analyst
                    .analyze(currencyCodeOfInterest: setting.currencyCodeOfInterest,
                             latestRate: latestRate,
                             historicalRateSet: historicalRateSet,
                             baseCurrencyCode: setting.baseCurrencyCode)
                
                let analyzedFailure = analyzedResult
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
                
                analyzedSortedDataArray = Self.sort(self.analyzedSortedDataArray,
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
