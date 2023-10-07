import Foundation

class BaseResultModel {
    #warning("這些屬性之後要擋起來 或者刪掉")
    var numberOfDay: Int
    
    var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var baseCurrency: ResponseDataModel.CurrencyCode
    
    var order: BaseResultModel.Order
    
    private var searchText: String?
    
    private var latestUpdateTime: Date?
    
    private var state: State
    
    private var analyzedDataArray: [AnalyzedData] = []
    
    #warning("還沒做自動更新")
    
    init() {
        numberOfDay = AppUtility.numberOfDay
        baseCurrency = AppUtility.baseCurrency
        currencyOfInterest = Set(AppUtility.currencyOfInterest)
        order = AppUtility.order
        searchText = String()
        latestUpdateTime =  nil
        
        state = .initialized
    }
    
    
    func updateData(numberOfDays: Int,
                    from start: Date = .now,
                    completionHandlerQueue: DispatchQueue = .main,
                    completionHandler: @escaping (BaseResultModel.State) -> Void) {
        state = .updating
        completionHandler(state)
        
        RateController.shared.getRateFor(numberOfDays: numberOfDays,
                                         from: start,
                                         completionHandlerQueue: completionHandlerQueue) { [unowned self] result in
            switch result {
            case .success(let (latestRate, historicalRateSet)):
                
                do {
                    let analyzedResult = Analyst
                        .analyze(currencyOfInterest: currencyOfInterest,
                                 latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrency: baseCurrency)
                    
                    let analyzedFailure = analyzedResult
                        .filter { _, result in
                            switch result {
                            case .failure: return true
                            case .success: return false
                            }
                        }
                    
                    guard analyzedFailure.isEmpty else {
                        state = .failure(MyError.foo)
                        completionHandler(state)
                        #warning("還沒處理錯誤")
                        return
                    }
                    
                    analyzedDataArray = analyzedResult
                        .compactMapValues { result in try? result.get() }
                        .map { tuple in
                            AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                        }
                    
                    let analyzedDataArray = self.sort(analyzedDataArray: analyzedDataArray,
                                                      by: self.order,
                                                      andFilteredIfNeededBy: self.searchText)
                    
                    state = .updated(time: latestRate.timestamp, analyzedDataArray: analyzedDataArray)
                    completionHandler(state)
                }
                
            case .failure(let error):
                state = .failure(error)
                completionHandler(state)
            }
        }
    }
    
    func updateDataFor(order: Order, completionHandler: @escaping (State) -> Void) {
        guard self.order != order else { return }
        
        self.order = order
        
        switch self.state {
        case .initialized:
            2
            #warning("還沒處理")
        case .updating:
            2
#warning("還沒處理")
        case .updated(let time, let analyzedDataArray):
            let analyzedDataArray = self.sort(analyzedDataArray: analyzedDataArray,
                                              by: self.order,
                                              andFilteredIfNeededBy: self.searchText)
            
            completionHandler(.updated(time: time, analyzedDataArray: analyzedDataArray))
            
        case .failure(let error):
            2
#warning("還沒處理")
        }
    }
    
    func updateDataFor(searchText: String?, completionHandler: @escaping (State) -> Void) {
        guard self.searchText != searchText else { return }
        self.searchText = searchText
        switch self.state  {
        case .initialized:
            2
#warning("還沒處理")
        case .updating:
            2
#warning("還沒處理")
        case .updated(let time, let analyzedDataArray):
            let analyzedDataArray = self.sort(analyzedDataArray: analyzedDataArray,
                                              by: self.order,
                                              andFilteredIfNeededBy: self.searchText)
            
            completionHandler(.updated(time: time, analyzedDataArray: analyzedDataArray))
            
        case .failure(let error):
            2
#warning("還沒處理")
        }
    }
    
    func updateDataFor(numberOfDays: Int,
                       baseCurrencyCode: ResponseDataModel.CurrencyCode,
                       currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
                       completionHandler: @escaping (State) -> Void) {
        self.numberOfDay = numberOfDays
        self.baseCurrency = baseCurrencyCode
        self.currencyOfInterest = currencyOfInterest
        updateData(numberOfDays: self.numberOfDay, completionHandler: completionHandler)
    }
}

private extension BaseResultModel {
    func sort(analyzedDataArray: [AnalyzedData], by order: Order, andFilteredIfNeededBy searchText: String?) -> [AnalyzedData] {
        analyzedDataArray
            .sorted { lhs, rhs in
                switch order {
                case .increasing:
                    return lhs.deviation < rhs.deviation
                case .decreasing:
                    return lhs.deviation > rhs.deviation
                }
            }
            .filter { analyzedData in
                guard let searchText, !searchText.isEmpty else { return true }
                
                return [analyzedData.currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: analyzedData.currencyCode)]
                    .compactMap { $0 }
                    .contains { text in text.localizedStandardContains(searchText) }
            }
    }
}

// MARK: - name space
extension BaseResultModel {
    /// 資料的排序方式。
    /// 因為要儲存在 UserDefaults，所以 access control 不能是 private。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedName: String {
            switch self {
            case .increasing: return R.string.resultScene.increasing()
            case .decreasing: return R.string.resultScene.decreasing()
            }
        }
    }
    
    typealias UserSetting = (numberOfDay: Int, baseCurrency: ResponseDataModel.CurrencyCode, currencyOfInterest: Set<ResponseDataModel.CurrencyCode>)
}

// MARK: - name space
extension BaseResultModel {
    enum State {
        case initialized
        case updating
        case updated(time: Int, analyzedDataArray: [AnalyzedData])
        case failure(Error)
    }
    
    struct AnalyzedData: Hashable {
        let currencyCode: ResponseDataModel.CurrencyCode
        let latest: Decimal
        let mean: Decimal
        let deviation: Decimal
    }
    
    enum MyError: Swift.Error, LocalizedError {
        case foo
        #warning("暫時用的error")
        var localizedDescription: String { "暫時用的error" }
        var errorDescription: String? { "暫時用的error" }
    }
}
