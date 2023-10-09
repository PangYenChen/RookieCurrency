import Foundation

class BaseResultModel {
#warning("這些屬性之後要擋起來 或者刪掉")
    var numberOfDays: Int
    
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode
    
    let initialOrder: Order
    
    private var order: Order
    
    private var searchText: String?
    
    private var latestUpdateTime: Date?
    
    private var state: State
    
    private var analyzedDataArray: [AnalyzedData] = []
    
#warning("還沒做自動更新")
    
    init() {
        numberOfDays = AppUtility.numberOfDay
        baseCurrencyCode = AppUtility.baseCurrency
        currencyCodeOfInterest = Set(AppUtility.currencyOfInterest)
        initialOrder = AppUtility.order
        order = initialOrder
        searchText = String()
        latestUpdateTime =  nil
        
        state = .initialized
    }
    
    func updateState(completionHandler: @escaping (BaseResultModel.State) -> Void) {
        updateStateFor(numberOfDays: self.numberOfDays, completionHandler: completionHandler)
    }
    
    func setOrderAndSortAnalyzedDataArray(order: Order) -> [AnalyzedData] {
        self.order = order
        return self.sort(self.analyzedDataArray,
                         by: self.order,
                         filteredIfNeededBy: self.searchText)
    }
    
    func setSearchTextAndFilterAnalyzedDataArray(searchText: String?) -> [AnalyzedData] {
        self.searchText = searchText
        return self.sort(self.analyzedDataArray,
                         by: self.order,
                         filteredIfNeededBy: self.searchText)
    }
    
    func updateStateFor(numberOfDays: Int,
                        baseCurrencyCode: ResponseDataModel.CurrencyCode,
                        currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
                        completionHandler: @escaping (State) -> Void) {
        self.numberOfDays = numberOfDays
        self.baseCurrencyCode = baseCurrencyCode
        self.currencyCodeOfInterest = currencyOfInterest
        updateStateFor(numberOfDays: self.numberOfDays, completionHandler: completionHandler)
    }
}

// MARK: - private method
private extension BaseResultModel {
    func updateStateFor(numberOfDays: Int,
                        completionHandler: @escaping (BaseResultModel.State) -> Void) {
        state = .updating
        completionHandler(state)
        
        RateController.shared.getRateFor(numberOfDays: numberOfDays) { [unowned self] result in
            switch result {
            case .success(let (latestRate, historicalRateSet)):
                
                do {
                    let analyzedResult = Analyst
                        .analyze(currencyOfInterest: currencyCodeOfInterest,
                                 latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrency: baseCurrencyCode)
                    
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
                    
                    let analyzedDataArray = self.sort(analyzedDataArray,
                                                      by: self.order,
                                                      filteredIfNeededBy: self.searchText)
                    
                    state = .updated(time: latestRate.timestamp, analyzedDataArray: analyzedDataArray)
                    completionHandler(state)
                }
                
            case .failure(let error):
                state = .failure(error)
                completionHandler(state)
            }
        }
    }
    
    func sort(_ analyzedDataArray: [AnalyzedData], by order: Order, filteredIfNeededBy searchText: String?) -> [AnalyzedData] {
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
