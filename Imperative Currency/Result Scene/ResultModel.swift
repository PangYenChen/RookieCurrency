import Foundation

class ResultModel: BaseResultModel {
    private var userSetting: UserSetting
    
    private var order: Order
    
    private var searchText: String?
    
    private var analyzedDataArray: [AnalyzedData]
    
    private var timer: Timer?
    
    private let autoUpdateTimeInterval: TimeInterval
    
    private var state: State
    
    var stateHandler: StateHandler? {
        didSet {
            stateHandler?(state)
        }
    }
    
    override init() {
        userSetting = (numberOfDay: AppUtility.numberOfDays,
                       baseCurrency: AppUtility.baseCurrencyCode,
                       currencyOfInterest: AppUtility.currencyCodeOfInterest)
        
        order = AppUtility.order
        
        searchText = nil
        analyzedDataArray = []
        
        timer = nil
        autoUpdateTimeInterval = 5
        
        state = .updating
        
        super.init()
        
        resumeAutoUpdatingState()
    }
    
    override func updateState() {
        analyzedDataFor(userSetting: userSetting)
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        AppUtility.order = order
        self.order = order
        
        let analyzedSortedDataArray = Self.sort(self.analyzedDataArray,
                                                by: self.order,
                                                filteredIfNeededBy: self.searchText)
        stateHandler?(.sorted(analyzedSortedDataArray: analyzedSortedDataArray))
    }
    
    override func setSearchText(_ searchText: String?) {
        self.searchText = searchText
        let analyzedSortedDataArray = Self.sort(self.analyzedDataArray,
                                                by: self.order,
                                                filteredIfNeededBy: self.searchText)
        stateHandler?(.sorted(analyzedSortedDataArray: analyzedSortedDataArray))
    }
    
    override func settingModel() -> SettingModel {
        suspendAutoUpdatingState()
        
        return SettingModel(userSetting: userSetting) { [unowned self] userSetting in
            self.userSetting = userSetting
            AppUtility.numberOfDays = userSetting.numberOfDay
            AppUtility.baseCurrencyCode = userSetting.baseCurrency
            AppUtility.currencyCodeOfInterest = userSetting.currencyOfInterest
            
            self.resumeAutoUpdatingState()
        } cancelCompletionHandler: { [unowned self] in
            self.resumeAutoUpdatingState()
        }
    }
}

// MARK: - private method
private extension ResultModel {
    func resumeAutoUpdatingState() {
        timer = Timer.scheduledTimer(withTimeInterval: autoUpdateTimeInterval, repeats: true) { [unowned self] _ in
            analyzedDataFor(userSetting: userSetting)
        }
        timer?.fire()
    }
    
    func suspendAutoUpdatingState() {
        timer?.invalidate()
        timer = nil
    }
    
    func analyzedDataFor(userSetting: UserSetting) {
        stateHandler?(.updating)
        
        RateController.shared.getRateFor(numberOfDays: userSetting.numberOfDay) { [unowned self] result in
            switch result {
            case .success(let (latestRate, historicalRateSet)):
                
                do {
                    let analyzedResult = Analyst
                        .analyze(currencyOfInterest: userSetting.currencyOfInterest,
                                 latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrency: userSetting.baseCurrency)
                    
                    let analyzedFailure = analyzedResult
                        .filter { _, result in
                            switch result {
                            case .failure: return true
                            case .success: return false
                            }
                        }
                    
                    guard analyzedFailure.isEmpty else {
                        state = .failure(MyError.foo)
                        stateHandler?(.failure(MyError.foo))
                    // TODO: 還沒處理錯誤"
                        return
                    }
                    
                    analyzedDataArray = analyzedResult
                        .compactMapValues { result in try? result.get() }
                        .map { tuple in
                            AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                        }
                    
                    let analyzedDataArray = Self.sort(self.analyzedDataArray,
                                                      by: self.order,
                                                      filteredIfNeededBy: self.searchText)
                    state = .updated(timestamp: latestRate.timestamp, analyzedDataArray: analyzedDataArray)
                    stateHandler?(.updated(timestamp: latestRate.timestamp, analyzedDataArray: analyzedDataArray))
                }
                
            case .failure(let error):
                state = .failure(error)
                stateHandler?(.failure(error))
            }
        }
    }
}

// MARK: - name space
extension ResultModel {
    typealias StateHandler = (_ state: State) -> Void
}
