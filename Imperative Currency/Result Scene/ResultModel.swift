import Foundation

class ResultModel: BaseResultModel {
#warning("這些屬性在 setting scene 改成 mvc 之後要擋起來 或者刪掉")
    
    private var userSetting: UserSetting
    
    private var order: Order
    
    private var searchText: String?
    
    private var analyzedDataArray: [AnalyzedData]
    
    private var timer: Timer?
    
    private let autoUpdateTimeInterval: TimeInterval
    
    var stateHandler: StateHandler?
    
    override init() {
        userSetting = (numberOfDay: AppUtility.numberOfDays,
                       baseCurrency: AppUtility.baseCurrencyCode,
                       currencyOfInterest: AppUtility.currencyCodeOfInterest)
        
        order = AppUtility.order
        
        searchText = nil
        analyzedDataArray = []
        
        timer = nil
        autoUpdateTimeInterval = 5
        
        super.init()
        
        resumeAutoUpdatingState()
    }
    
    override func updateState() {
        analyzedDataFor(userSetting: userSetting)
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        AppUtility.order = order
        self.order = order
        
        let analyzedDataArray = Self.sort(self.analyzedDataArray,
                                          by: self.order,
                                          filteredIfNeededBy: self.searchText)
        stateHandler?(.sorted(analyzedDataArray: analyzedDataArray))
    }
    
    override func setSearchText(_ searchText: String?) {
        self.searchText = searchText
        let analyzedDataArray = Self.sort(self.analyzedDataArray,
                                          by: self.order,
                                          filteredIfNeededBy: self.searchText)
        stateHandler?(.sorted(analyzedDataArray: analyzedDataArray))
    }
}

// MARK: - internal methods
extension ResultModel {
    
    func settingModel() -> SettingModel {
        suspendAutoUpdatingState()
        
        return SettingModel(userSetting: userSetting) { [unowned self] userSetting in
            self.userSetting = userSetting
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
                        stateHandler?(.failure(MyError.foo))
#warning("還沒處理錯誤")
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
                    
                    stateHandler?(.updated(timestamp: latestRate.timestamp, analyzedDataArray: analyzedDataArray))
                }
                
            case .failure(let error):
                stateHandler?(.failure(error))
            }
        }
    }
}

// MARK: - name space
extension ResultModel {
    typealias StateHandler = (_ state: State) -> Void
}
