import Foundation
import Combine

class ResultModel: BaseResultModel {
    // MARK: - private properties
    private let userSetting: CurrentValueSubject<BaseResultModel.UserSetting, Never>
    private let userTriggeredStateUpdating: CurrentValueSubject<Void, Never>
    private let order: CurrentValueSubject<Order, Never>
    private let searchText: CurrentValueSubject<String?, Never>
    private let enableAutoUpdateState: CurrentValueSubject<Bool, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: output
    let state: AnyPublisher<State, Never>
    
    override init() {
        // input
        userSetting = CurrentValueSubject((AppUtility.numberOfDays, AppUtility.baseCurrencyCode, AppUtility.currencyCodeOfInterest))
        userTriggeredStateUpdating = CurrentValueSubject<Void, Never>(())
        
        searchText = CurrentValueSubject<String?, Never>(nil)
        
        order = CurrentValueSubject<BaseResultModel.Order, Never>(AppUtility.order)
        
        enableAutoUpdateState = CurrentValueSubject<Bool, Never>(true)
        
        // output
        do {
            let autoUpdateTimeInterval: TimeInterval = 5
            
            let autoUpdateState = enableAutoUpdateState
                .map { isEnable in
                    isEnable ?
                    Timer.publish(every: autoUpdateTimeInterval, on: RunLoop.main, in: .default)
                        .autoconnect()
                        .map { _ in return }
                        .eraseToAnyPublisher() :
                    Empty<Void, Never>()
                        .eraseToAnyPublisher()
                }
                .switchToLatest()
            
            let updateState = Publishers.Merge(userTriggeredStateUpdating, autoUpdateState)
            
            let shouldUpdateRate = Publishers.CombineLatest(updateState, userSetting)
            
            let analyzedSuccessTuple = shouldUpdateRate
                .flatMap { _, userSetting in
                    RateController.shared
                        .ratePublisher(numberOfDay: userSetting.numberOfDay)
                        .convertOutputToResult()
                        .map { result in
                            result.map { rateTuple in
                                let analyzedDataArray = Analyst.analyze(currencyOfInterest: userSetting.currencyOfInterest,
                                                                        latestRate: rateTuple.latestRate,
                                                                        historicalRateSet: rateTuple.historicalRateSet,
                                                                        baseCurrency: userSetting.baseCurrency)
                                    .compactMapValues { result in try? result.get() }
                                    .map { tuple in
                                        AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                                    }
                                return (latestUpdateTime: rateTuple.latestRate.timestamp, analyzedDataArray: analyzedDataArray)
                            }
                        }
                    
                }
                .resultSuccess()
#warning("還沒處理錯誤，要提示使用者即將刪掉本地的資料，重新從網路上拿")
            
            let orderAndSearchText = Publishers.CombineLatest(order, searchText)
                .map { (order: $0, searchText: $1) }
            
            state = Publishers.CombineLatest(analyzedSuccessTuple, orderAndSearchText)
                .map { analyzedSuccessTuple, orderAndSearchText in
                    let analyzedDataArray = Self.sort(analyzedSuccessTuple.analyzedDataArray,
                                                      by: orderAndSearchText.order,
                                                      filteredIfNeededBy: orderAndSearchText.searchText)
                    return State.updated(timestamp: analyzedSuccessTuple.latestUpdateTime,
                                         analyzedDataArray: analyzedDataArray)
                }
                .eraseToAnyPublisher()
        }
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init()
        
        userSetting
            .dropFirst()
            .sink { [unowned self] userSetting in
                AppUtility.baseCurrencyCode = userSetting.baseCurrency
                AppUtility.currencyCodeOfInterest = userSetting.currencyOfInterest
                AppUtility.numberOfDays = userSetting.numberOfDay
                #warning("下面這行暫時先這樣，之後改成這個model跟setting model之間的溝通")
                self.enableAutoUpdateState.send(true)
            }
            .store(in: &anyCancellableSet)
    }
    
    // MARK: - hook methods
    override func updateState() {
        userTriggeredStateUpdating.send()
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        AppUtility.order = order
        self.order.send(order)
    }
    
    override func setSearchText(_ searchText: String?) {
        self.searchText.send(searchText)
    }
    
    override func settingModel() -> SettingModel {
        enableAutoUpdateState.send(false)
        return SettingModel(userSetting: userSetting.value,
                            settingSubscriber: AnySubscriber(userSetting),
                            // TODO: handle cancel
                            cancelSubscriber: AnySubscriber<Void, Never>())
    }
}
