import Foundation

class ResultModel: BaseResultModel {
#warning("這些屬性在 setting scene 改成 mvc 之後要擋起來 或者刪掉")
    var numberOfDays: Int
    
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode
    
    private var order: Order
    
    private var searchText: String?
    
    private var analyzedDataArray: [AnalyzedData]
    
    private var timer: Timer?
    
    private let autoUpdateTimeInterval: TimeInterval
    
    var stateHandler: StateHandler?
    
    override init() {
        numberOfDays = AppUtility.numberOfDays
        baseCurrencyCode = AppUtility.baseCurrencyCode
        currencyCodeOfInterest = AppUtility.currencyCodeOfInterest
        order = AppUtility.order
        
        searchText = nil
        analyzedDataArray = []
        
        timer = nil
        autoUpdateTimeInterval = 5
        
        super.init()
    }
    
    override func updateState() {
        analyzedDataFor(numberOfDays: self.numberOfDays,
                        baseCurrencyCode: self.baseCurrencyCode,
                        currencyCodeOfInterest: self.currencyCodeOfInterest)
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
    
    func updateStateFor(numberOfDays: Int,
                        baseCurrencyCode: ResponseDataModel.CurrencyCode,
                        currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
                        completionHandler: @escaping (State) -> Void) {
        // TODO: 移除 complement handler
        AppUtility.numberOfDays = numberOfDays
        self.numberOfDays = numberOfDays
        
        AppUtility.baseCurrencyCode = baseCurrencyCode
        self.baseCurrencyCode = baseCurrencyCode
        
        AppUtility.currencyCodeOfInterest = currencyCodeOfInterest
        self.currencyCodeOfInterest = currencyCodeOfInterest
        
        analyzedDataFor(numberOfDays: self.numberOfDays,
                        baseCurrencyCode: self.baseCurrencyCode,
                        currencyCodeOfInterest: self.currencyCodeOfInterest)
    }
    
    func resumeAutoUpdatingState() {
        timer = Timer.scheduledTimer(withTimeInterval: autoUpdateTimeInterval, repeats: true) { [unowned self] _ in
            analyzedDataFor(numberOfDays: self.numberOfDays,
                            baseCurrencyCode: self.baseCurrencyCode,
                            currencyCodeOfInterest: self.currencyCodeOfInterest)
        }
        timer?.fire()
    }
    
    func resumeAutoUpdatingStateFor(numberOfDays: Int,
                                    baseCurrencyCode: ResponseDataModel.CurrencyCode,
                                    currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
                                    completionHandler: @escaping (State) -> Void) {
        // TODO: remove completion handler
        AppUtility.numberOfDays = numberOfDays
        self.numberOfDays = numberOfDays
        
        AppUtility.baseCurrencyCode = baseCurrencyCode
        self.baseCurrencyCode = baseCurrencyCode
        
        AppUtility.currencyCodeOfInterest = currencyCodeOfInterest
        self.currencyCodeOfInterest = currencyCodeOfInterest
        
        resumeAutoUpdatingState(/*completionHandler: completionHandler*/)
    }
    
    func suspendAutoUpdatingState() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - private method
private extension ResultModel {
    func analyzedDataFor(numberOfDays: Int,
                         baseCurrencyCode: ResponseDataModel.CurrencyCode,
                         currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>) {
        stateHandler?(.updating)
        
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
