import Foundation
import Combine

class ResultModel: BaseResultModel {
    // MARK: - input
    private let userSetting: CurrentValueSubject<BaseResultModel.UserSetting, Never>
    private let updateTriggerByUser: PassthroughSubject<Void, Never>
    private let order: CurrentValueSubject<Order, Never>
    private let searchText: CurrentValueSubject<String?, Never>
    private let enableAutoUpdate: CurrentValueSubject<Void, Never>
    private let disableAutoUpdate: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: output
    let state: AnyPublisher<State, Never>
    
    override init() {
        // input
        do {
            userSetting = CurrentValueSubject((AppUtility.numberOfDays,
                                               AppUtility.baseCurrencyCode,
                                               AppUtility.currencyCodeOfInterest))
            
            updateTriggerByUser = PassthroughSubject<Void, Never>()
            
            searchText = CurrentValueSubject<String?, Never>(nil)
            
            order = CurrentValueSubject<BaseResultModel.Order, Never>(AppUtility.order)
            
            enableAutoUpdate = CurrentValueSubject<Void, Never>(())
            
            disableAutoUpdate = PassthroughSubject<Void, Never>()
        }
        
        let settingFromSettingModel = userSetting.dropFirst()
        
        // output
        do {
            let autoUpdate: AnyPublisher<Void, Never>
            
            do {
                let autoUpdateTimeInterval: TimeInterval = 5
                
                let timerPublisher = Publishers.Merge(enableAutoUpdate,
                                                       settingFromSettingModel.map { _ in })
                    .map { _ in
                        Timer.publish(every: autoUpdateTimeInterval, on: RunLoop.main, in: .default)
                            .autoconnect()
                            .map { _ in return }
                            .eraseToAnyPublisher()
                    }
                
                let emptyPublisher = disableAutoUpdate.map { Empty<Void, Never>().eraseToAnyPublisher() }
                
                autoUpdate = Publishers.Merge(timerPublisher, emptyPublisher)
                    .switchToLatest()
                    .eraseToAnyPublisher()
            }
            
            let update = Publishers.Merge(updateTriggerByUser, autoUpdate)
            
            let analyzedSuccessTuple = Publishers.CombineLatest(update, userSetting)
                .flatMap { _, userSetting in
                    RateController.shared
                        .ratePublisher(numberOfDays: userSetting.numberOfDays)
                        .convertOutputToResult()
                        .map { result in
                            result.map { rateTuple in
                                let analyzedDataArray = Analyst
                                    .analyze(currencyCodeOfInterest: userSetting.currencyCodeOfInterest,
                                             latestRate: rateTuple.latestRate,
                                             historicalRateSet: rateTuple.historicalRateSet,
                                             baseCurrencyCode: userSetting.baseCurrencyCode)
                                    .compactMapValues { result in try? result.get() }
                                    .map { tuple in
                                        AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                                    }
                                return (latestUpdateTime: rateTuple.latestRate.timestamp, analyzedDataArray: analyzedDataArray)
                            }
                        }
                }
                .resultSuccess()
            // TODO: 還沒處理錯誤，要提示使用者即將刪掉本地的資料，重新從網路上拿
            
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
                .merge(with: update.map { .updating })
                .eraseToAnyPublisher()
        }
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init()
        
        // subscribe
        do {
            settingFromSettingModel
                .sink { userSetting in
                    AppUtility.baseCurrencyCode = userSetting.baseCurrencyCode
                    AppUtility.currencyCodeOfInterest = userSetting.currencyCodeOfInterest
                    AppUtility.numberOfDays = userSetting.numberOfDays
                }
                .store(in: &anyCancellableSet)
            
            order
                .dropFirst()
                .sink { order in AppUtility.order = order }
                .store(in: &anyCancellableSet)
        }
    }
    
    // MARK: - hook methods
    override func updateState() {
        updateTriggerByUser.send()
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        self.order.send(order)
    }
    
    override func setSearchText(_ searchText: String?) {
        self.searchText.send(searchText)
    }
    
    override func settingModel() -> SettingModel {
        disableAutoUpdate.send()
        return SettingModel(userSetting: userSetting.value,
                            settingSubscriber: AnySubscriber(userSetting),
                            cancelSubscriber: AnySubscriber(enableAutoUpdate))
    }
}
