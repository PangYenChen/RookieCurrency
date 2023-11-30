import Foundation
import Combine

class ResultModel: BaseResultModel {
    // MARK: - input
    private let userSetting: CurrentValueSubject<BaseResultModel.UserSetting, Never>
    private let updateTriggerByUser: PassthroughSubject<Void, Never>
    private let order: CurrentValueSubject<Order, Never>
    private let searchText: CurrentValueSubject<String?, Never>
    private let isAutoUpdateEnabled: CurrentValueSubject<Bool, Never>
    
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
            
            isAutoUpdateEnabled = CurrentValueSubject<Bool, Never>(true)
        }
        // output
        do {
            let autoUpdateTimeInterval: TimeInterval = 5
            
            let autoUpdate = isAutoUpdateEnabled
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
            
            let update = Publishers.Merge(updateTriggerByUser, autoUpdate)
            
            let analyzedSuccessTuple = Publishers.CombineLatest(update, userSetting)
                .flatMap { _, userSetting in
                    RateController.shared
                        .ratePublisher(numberOfDays: userSetting.numberOfDays)
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
        
        userSetting
            .dropFirst()
            .sink { [unowned self] userSetting in
                AppUtility.baseCurrencyCode = userSetting.baseCurrency
                AppUtility.currencyCodeOfInterest = userSetting.currencyOfInterest
                AppUtility.numberOfDays = userSetting.numberOfDays
                // TODO: 下面這行暫時先這樣，之後改成這個model跟setting model之間的溝通
                self.isAutoUpdateEnabled.send(true)
            }
            .store(in: &anyCancellableSet)
        
        order
            .dropFirst()
            .sink { order in AppUtility.order = order }
            .store(in: &anyCancellableSet)
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
        isAutoUpdateEnabled.send(false)
        return SettingModel(userSetting: userSetting.value,
                            settingSubscriber: AnySubscriber(userSetting),
                            // TODO: handle cancel
                            cancelSubscriber: AnySubscriber<Void, Never>())
    }
}
