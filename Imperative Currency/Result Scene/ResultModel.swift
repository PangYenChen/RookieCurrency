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
        userSetting = (numberOfDays: AppUtility.numberOfDays,
                       baseCurrencyCode: AppUtility.baseCurrencyCode,
                       currencyCodeOfInterest: AppUtility.currencyCodeOfInterest)
        
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
            AppUtility.numberOfDays = userSetting.numberOfDays
            AppUtility.baseCurrencyCode = userSetting.baseCurrencyCode
            AppUtility.currencyCodeOfInterest = userSetting.currencyCodeOfInterest
            
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
        
        RateController.shared.getRateFor(numberOfDays: userSetting.numberOfDays) { [unowned self] result in
            switch result {
            case .success(let (latestRate, historicalRateSet)):
                
                do {
                    let analyzedResult = Analyst
                        .analyze(currencyCodeOfInterest: userSetting.currencyCodeOfInterest,
                                 latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrencyCode: userSetting.baseCurrencyCode)
                    
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
