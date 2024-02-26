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
    
    // MARK: - dependencies
    private var userSettingManager: UserSettingManagerProtocol
    
    private let rateManager: RateManagerProtocol
    
    private let analyzedDataSorter: BaseResultModel.AnalyzedDataSorter
    
    // MARK: - private properties
    
    /// 要傳遞到 setting scene 的資料，可以在那邊修改
    private var setting: Setting
    
    /// 同樣是 user setting 的一部份，跟 `setting` 不同的是，`order` 在這個 scene 修改
    private var order: Order
    
    private var searchText: String?
    
    private var latestUpdateTimestamp: Int?
    
    private var analyzedSortedDataArray: [AnalyzedData]
    
    private var timer: Timer?
    
    private var state: State // TODO: to be removed
    
    // MARK: - internal property
    var stateHandler: StateHandler? { // TODO: to be removed
        didSet {
            stateHandler?(state)
        }
    }
}

// MARK: - methods
extension ResultModel {
    func refresh(_ completionHandler: @escaping CompletionHandler) {
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
                    
//                    state = .updated(timestamp: latestRate.timestamp, analyzedSortedDataArray: analyzedSortedDataArray)
                    latestUpdateTimestamp = latestRate.timestamp
                    
                    let success: Success = (updatedTimestamp: latestRate.timestamp, analyzedSortedDataArray: analyzedSortedDataArray)
                    completionHandler(.success(success))
                    
//                    stateHandler?(state)
                    
                case .failure(let error):
                    let failure = Failure(latestUpdateTimestamp: latestUpdateTimestamp, underlyingError: error)
                    completionHandler(.failure(failure))
//                    state = .failure(error)
//                    stateHandler?(state)
            }
        }
    }
    
    func setOrder(_ order: BaseResultModel.Order) {
        userSettingManager.resultOrder = order
        self.order = order
        
        analyzedSortedDataArray = analyzedDataSorter.sort(self.analyzedSortedDataArray,
                                                          by: self.order,
                                                          filteredIfNeededBy: self.searchText)
        
        state = .sorted(analyzedSortedDataArray: analyzedSortedDataArray)
        
        stateHandler?(state)
    }
    
    func setSearchText(_ searchText: String?) {
        self.searchText = searchText
        
        analyzedSortedDataArray = analyzedDataSorter.sort(self.analyzedSortedDataArray,
                                                          by: self.order,
                                                          filteredIfNeededBy: self.searchText)
        
        state = .sorted(analyzedSortedDataArray: analyzedSortedDataArray)
        
        stateHandler?(state)
    }
}

// MARK: - SettingModelFactory
extension ResultModel {
    func makeSettingModel() -> SettingModel {
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
    typealias StateHandler = (_ state: State) -> Void // TODO: to be removed
    typealias Success = (updatedTimestamp: Int, analyzedSortedDataArray: [AnalyzedData])
    
    struct Failure: Error {
        let latestUpdateTimestamp: Int?
        let underlyingError: Error
    }
    
    typealias CompletionHandler = (_ result: Result<Success, Failure>) -> Void
}
