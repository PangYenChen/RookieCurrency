import Foundation

class BaseResultModel {
    var numberOfDay: Int
    
    var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var baseCurrency: ResponseDataModel.CurrencyCode
    
    var order: BaseResultModel.Order
    
    var searchText: String
    
    var latestUpdateTime: Date?
    
    init() {
        numberOfDay = AppUtility.numberOfDay
        baseCurrency = AppUtility.baseCurrency
        currencyOfInterest = Set(AppUtility.currencyOfInterest)
        order = AppUtility.order
        searchText = String()
        latestUpdateTime =  nil
    }
    
    
    func updateData(numberOfDays: Int,
                    from start: Date = .now,
                    completionHandlerQueue: DispatchQueue = .main,
                    completionHandler: @escaping (BaseResultModel.State) -> Void) {
        
        completionHandler(.updating)
        
        RateController.shared.getRateFor(numberOfDays: numberOfDays,
                                         from: start,
                                         completionHandlerQueue: .main) { [unowned self] result in
            switch result {
            case .success(let (latestRate, historicalRateSet)):
                
                do {
                    let analyzedResult = Analyst
                        .analyze(currencyOfInterest: currencyOfInterest,
                                 latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrency: baseCurrency)
                    
                    var analyzedDataArray = analyzedResult
                        .compactMapValues { result in try? result.get() }
                        .sorted { lhs, rhs in
                            switch order {
                            case .increasing:
                                return lhs.value.deviation < rhs.value.deviation
                            case .decreasing:
                                return lhs.value.deviation > rhs.value.deviation
                            }
                        }
                        .map { tuple in
                            AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                        }
                    
                    if !searchText.isEmpty { // filtering if needed
                        analyzedDataArray = analyzedDataArray
                            .filter { analyzedData in
                                [analyzedData.currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: analyzedData.currencyCode)]
                                    .compactMap { $0 }
                                    .contains { text in text.localizedStandardContains(searchText) }
                            }
                    }
                    
                    completionHandler(.updated(time: latestRate.timestamp, analyzedDataArray: analyzedDataArray))
                    
             
                }
                
            case .failure(let error):
                3
            }
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


extension BaseResultModel {
    enum State {
        case updating
        case updated(time: Int, analyzedDataArray: [AnalyzedData])
    }
    
    struct AnalyzedData: Hashable {
        let currencyCode: ResponseDataModel.CurrencyCode
        let latest: Decimal
        let mean: Decimal
        let deviation: Decimal
    }
}
