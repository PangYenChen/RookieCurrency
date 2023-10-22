import Foundation
import Combine

class ResultModel: BaseResultModel {
    // MARK: - internal properties
    // MARK: input
    let userSetting: CurrentValueSubject<BaseResultModel.UserSetting, Never>
    
    let order: AnySubscriber<Order, Never>
    
    let searchText: AnySubscriber<String?, Never>
    
    let updateState: AnySubscriber<Void, Never>
    
    let enableAutoUpdateState: AnySubscriber<Bool, Never>
    
    // MARK: output
    let state: AnyPublisher<State, Never>
    
    // MARK: - private property
    private var anyCancellableSet: Set<AnyCancellable>
    
    override init() {
        // input
        userSetting = CurrentValueSubject((AppUtility.numberOfDays, AppUtility.baseCurrencyCode, AppUtility.currencyCodeOfInterest))
        
        let orderPublisher = CurrentValueSubject<BaseResultModel.Order, Never>(AppUtility.order)
        order = AnySubscriber(orderPublisher)
        
        let searchTextPublisher = CurrentValueSubject<String?, Never>(nil)
        searchText = AnySubscriber(searchTextPublisher)
        
        let userTriggeredStateUpdating = CurrentValueSubject<Void, Never>(())
        updateState = AnySubscriber(userTriggeredStateUpdating)
        
        let enableAutoUpdateStatePublisher = CurrentValueSubject<Bool, Never>(true)
        enableAutoUpdateState = AnySubscriber(enableAutoUpdateStatePublisher)
        
        
        // output
        do {
            let autoUpdateTimeInterval: TimeInterval = 5
            
            let autoUpdateState = enableAutoUpdateStatePublisher
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
            
            
            let orderAndSearchText = Publishers.CombineLatest(orderPublisher, searchTextPublisher)
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
            .sink { userSetting in
                AppUtility.baseCurrencyCode = userSetting.baseCurrency
                AppUtility.currencyCodeOfInterest = userSetting.currencyOfInterest
                AppUtility.numberOfDays = userSetting.numberOfDay
                #warning("下面這行暫時先這樣，之後改成這個model跟setting model之間的溝通")
                enableAutoUpdateStatePublisher.send(true)
            }
            .store(in: &anyCancellableSet)
        
        orderPublisher
            .dropFirst()
            .sink { order in AppUtility.order = order }
            .store(in: &anyCancellableSet)
    }
}
