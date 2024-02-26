import Foundation
import Combine

class ResultModel: BaseResultModel {
    // MARK: - initializer
    init(
        currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared,
        rateManager: RateManagerProtocol = RateManager.shared,
        userSettingManager: UserSettingManagerProtocol = UserSettingManager.shared
    ) {
        var userSettingManager = userSettingManager
        
        // input
        do {
            setting = CurrentValueSubject((userSettingManager.numberOfDays,
                                           userSettingManager.baseCurrencyCode,
                                           userSettingManager.currencyCodeOfInterest))
            
            updateTriggerByUser = PassthroughSubject<Void, Never>()
            
            searchText = CurrentValueSubject<String?, Never>(nil)
            
            order = CurrentValueSubject<BaseResultModel.Order, Never>(userSettingManager.resultOrder)
            
            enableAutoUpdate = CurrentValueSubject<Void, Never>(())
            
            disableAutoUpdate = PassthroughSubject<Void, Never>()
        }
        
        let settingFromSettingModel = setting.dropFirst()
        
        // output
        do {
            let update: AnyPublisher<Void, Never>
            
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
                                .prepend(()) // start immediately after subscribing
                                .eraseToAnyPublisher()
                        }
                    
                    let emptyPublisher = disableAutoUpdate.map { Empty<Void, Never>().eraseToAnyPublisher() }
                    
                    autoUpdate = Publishers.Merge(timerPublisher, emptyPublisher)
                        .switchToLatest()
                        .eraseToAnyPublisher()
                }
                
                update = Publishers.Merge(updateTriggerByUser, autoUpdate).eraseToAnyPublisher()
            }
            
            let updatingStatePublisher = update.map { State.updating }
            
            let analyzedResult = update.withLatestFrom(setting)
                .flatMap { _, setting in
                    rateManager
                        .ratePublisher(numberOfDays: setting.numberOfDays)
                        .convertOutputToResult()
                        .map { result in
                            result.map { rateTuple in
                                let analyzedDataArray = Analyst
                                    .analyze(currencyCodeOfInterest: setting.currencyCodeOfInterest,
                                             latestRate: rateTuple.latestRate,
                                             historicalRateSet: rateTuple.historicalRateSet,
                                             baseCurrencyCode: setting.baseCurrencyCode)
                                    .compactMapValues { result in try? result.get() }
                                // TODO: 還沒處理錯誤，要提示使用者即將刪掉本地的資料，重新從網路上拿
                                    .map { tuple in
                                        AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                                    }
                                return (latestUpdateTime: rateTuple.latestRate.timestamp, analyzedDataArray: analyzedDataArray)
                            }
                        }
                }
                .share()
            
            let failureStatePublisher = analyzedResult.resultFailure().map { error in State.failure(error) }
            
            let analyzedSuccessTuple = analyzedResult.resultSuccess()
            
            let orderAndSearchText = Publishers.CombineLatest(order, searchText)
                .map { (order: $0, searchText: $1) }
            
            let analyzedDataSorter = AnalyzedDataSorter(currencyDescriber: currencyDescriber)
            
            let updatedStatePublisher = analyzedSuccessTuple.withLatestFrom(orderAndSearchText)
                .map { analyzedSuccessTuple, orderAndSearchText in
                    let analyzedSortedDataArray = analyzedDataSorter.sort(analyzedSuccessTuple.analyzedDataArray,
                                                                          by: orderAndSearchText.order,
                                                                          filteredIfNeededBy: orderAndSearchText.searchText)
                    return State.updated(timestamp: analyzedSuccessTuple.latestUpdateTime,
                                         analyzedSortedDataArray: analyzedSortedDataArray)
                }
                .eraseToAnyPublisher()
            
            let sortedStatePublisher = orderAndSearchText.withLatestFrom(analyzedSuccessTuple)
                .map { (orderAndSearchText, analyzedSuccessTuple) in
                    let analyzedSortedDataArray = analyzedDataSorter.sort(analyzedSuccessTuple.analyzedDataArray,
                                                                          by: orderAndSearchText.order,
                                                                          filteredIfNeededBy: orderAndSearchText.searchText)
                    return State.sorted(analyzedSortedDataArray: analyzedSortedDataArray)
                }
                .eraseToAnyPublisher()
            
            state = Publishers
                .Merge4(updatingStatePublisher.print("#### updating state"),
                        updatedStatePublisher.print("#### updated state"),
                        sortedStatePublisher.print("#### sorted state"),
                        failureStatePublisher.print("#### failure"))
                .eraseToAnyPublisher()
        }
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(currencyDescriber: currencyDescriber,
                   userSettingManager: userSettingManager)
        
        // subscribe
        do {
            settingFromSettingModel
                .sink { setting in
                    userSettingManager.baseCurrencyCode = setting.baseCurrencyCode
                    userSettingManager.currencyCodeOfInterest = setting.currencyCodeOfInterest
                    userSettingManager.numberOfDays = setting.numberOfDays
                }
                .store(in: &anyCancellableSet)
            
            order
                .dropFirst()
                .sink { order in userSettingManager.resultOrder = order }
                .store(in: &anyCancellableSet)
        }
    }
    
    // MARK: - input
    private let setting: CurrentValueSubject<BaseResultModel.Setting, Never>
    private let updateTriggerByUser: PassthroughSubject<Void, Never>
    private let order: CurrentValueSubject<Order, Never>
    private let searchText: CurrentValueSubject<String?, Never>
    private let enableAutoUpdate: CurrentValueSubject<Void, Never>
    private let disableAutoUpdate: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: output
    let state: AnyPublisher<State, Never>
    
    // MARK: - hook methods
    func updateState() {
        updateTriggerByUser.send()
    }
    
    func setOrder(_ order: BaseResultModel.Order) {
        self.order.send(order)
    }
    
    override func setSearchText(_ searchText: String?) {
        self.searchText.send(searchText)
    }
    
    override func settingModel() -> SettingModel {
        disableAutoUpdate.send()
        return SettingModel(setting: setting.value,
                            settingSubscriber: AnySubscriber(setting),
                            cancelSubscriber: AnySubscriber(enableAutoUpdate))
    }
}
