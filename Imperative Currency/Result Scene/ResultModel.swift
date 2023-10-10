import Foundation

class ResultModel: BaseResultModel {
#warning("這些屬性之後要擋起來 或者刪掉")
    var numberOfDays: Int
    
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode
    
    private var order: Order
    
    private var searchText: String?
    
    private var latestUpdateTime: Date?
    
    private var analyzedDataArray: [AnalyzedData]
    
#warning("還沒做自動更新")
    
    override init() {
        numberOfDays = AppUtility.numberOfDay
        baseCurrencyCode = AppUtility.baseCurrency
        currencyCodeOfInterest = Set(AppUtility.currencyOfInterest)
        order = AppUtility.order
        searchText = nil
        latestUpdateTime =  nil
        analyzedDataArray = []
        
        super.init()
    }
}

// MARK: - internal methods
extension ResultModel {
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
private extension ResultModel {
    func updateStateFor(numberOfDays: Int,
                        completionHandler: @escaping (BaseResultModel.State) -> Void) {
        completionHandler(.updating)
        
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
                        completionHandler(.failure(MyError.foo))
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
                    
                    completionHandler(.updated(timestamp: latestRate.timestamp, analyzedDataArray: analyzedDataArray))
                }
                
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}
