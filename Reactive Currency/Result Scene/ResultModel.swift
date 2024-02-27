import Foundation
import Combine

class ResultModel: BaseResultModel {
    // MARK: - initializer
    init(
        currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared,
        rateManager: RateManagerProtocol = RateManager.shared,
        userSettingManager: UserSettingManagerProtocol = UserSettingManager.shared
    ) {
        var userSettingManager: UserSettingManagerProtocol = userSettingManager
        
        // input
        do {
            setting = CurrentValueSubject((userSettingManager.numberOfDays,
                                           userSettingManager.baseCurrencyCode,
                                           userSettingManager.currencyCodeOfInterest))
            
            refreshTriggerByUser = PassthroughSubject<Void, Never>()
            
            searchText = CurrentValueSubject<String?, Never>(nil)
            
            order = CurrentValueSubject<BaseResultModel.Order, Never>(userSettingManager.resultOrder)
            
            resumeAutoRefresh = CurrentValueSubject<Void, Never>(())
            
            suspendAutoRefresh = PassthroughSubject<Void, Never>()
        }
        
        let settingFromSettingModel: AnyPublisher<Setting, Never> = setting.dropFirst().eraseToAnyPublisher() // TODO: 改成屬性
        
        do /*output*/ {
            let refresh: AnyPublisher<Void, Never>
            
            do {
                let autoRefresh: AnyPublisher<Void, Never>
                
                do {
                    let timerPublisher: AnyPublisher<AnyPublisher<Void, Never>, Never> = Publishers
                        .Merge(resumeAutoRefresh,
                               settingFromSettingModel.map { _ in })
                        .map { _ in
                            Timer.publish(every: Self.autoRefreshTimeInterval, on: RunLoop.main, in: .default)
                                .autoconnect()
                                .map { _ in }
                                .prepend(()) // start immediately after subscribing
                                .eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                    
                    let emptyPublisher: AnyPublisher<AnyPublisher<Void, Never>, Never> = suspendAutoRefresh
                        .map { Empty<Void, Never>().eraseToAnyPublisher() }
                        .eraseToAnyPublisher()
                    
                    autoRefresh = Publishers.Merge(timerPublisher, emptyPublisher)
                        .switchToLatest()
                        .eraseToAnyPublisher()
                }
                
                refresh = Publishers.Merge(refreshTriggerByUser, autoRefresh).eraseToAnyPublisher()
            }
            
            let analyzedResult: AnyPublisher<Result<(latestUpdateTime: Int, analyzedDataArray: [QuasiBaseResultModel.AnalyzedData]), Error>, Never> = refresh.withLatestFrom(setting)
                .flatMap { _, setting in
                    rateManager
                        .ratePublisher(numberOfDays: setting.numberOfDays)
                        .convertOutputToResult()
                        .map { result in
                            result.map { rateTuple in
                                let analyzedDataArray: [QuasiBaseResultModel.AnalyzedData] = Analyst
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
                .eraseToAnyPublisher()
            
            error = analyzedResult.resultFailure()
            
            let refreshStatusIdle: AnyPublisher<QuasiBaseResultModel.RefreshStatus, Never> = analyzedResult.resultSuccess()
                .map { tuple in QuasiBaseResultModel.RefreshStatus.idle(latestUpdateTimestamp: tuple.latestUpdateTime) }
                .eraseToAnyPublisher() // TODO: 還沒處理失敗後回傳上一次的時間
            
            let orderAndSearchText: AnyPublisher<(order: Order, searchText: String?), Never> = Publishers.CombineLatest(order, searchText)
                .map { (order: $0, searchText: $1) }
                .eraseToAnyPublisher()
            
            let analyzedDataSorter: AnalyzedDataSorter = AnalyzedDataSorter(currencyDescriber: currencyDescriber)
            
            analyzedDataArray = analyzedResult.resultSuccess()
                .map { tuple in tuple.analyzedDataArray }
                .withLatestFrom(orderAndSearchText)
                .map { analyzedDataArray, orderAndSearchText in
                    analyzedDataSorter.sort(analyzedDataArray,
                                            by: orderAndSearchText.order,
                                            filteredIfNeededBy: orderAndSearchText.searchText)
                }
                .eraseToAnyPublisher()
        }
        
        refreshStatus = Empty().eraseToAnyPublisher() // TODO:
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(currencyDescriber: currencyDescriber,
                   userSettingManager: userSettingManager)
        
        do /*subscribe*/ {
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
    /// 是 user setting 的一部份，要傳遞到 setting scene 的資料，在那邊編輯
    private let setting: CurrentValueSubject<BaseResultModel.Setting, Never>
    
    /// 是 user setting 的一部份，跟 `setting` 不同的是，`order` 在這個 scene 修改
    private let order: CurrentValueSubject<Order, Never>
    
    private let refreshTriggerByUser: PassthroughSubject<Void, Never>
    
    private let searchText: CurrentValueSubject<String?, Never>
    
    private let resumeAutoRefresh: CurrentValueSubject<Void, Never>
    
    private let suspendAutoRefresh: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: output
    let analyzedDataArray: AnyPublisher<[QuasiBaseResultModel.AnalyzedData], Never>
    
    let refreshStatus: AnyPublisher<QuasiBaseResultModel.RefreshStatus, Never>
    
    let error: AnyPublisher<Error, Never>
}

// MARK: - methods
extension ResultModel {
    func refresh() {
        refreshTriggerByUser.send()
    }
    
    func setOrder(_ order: BaseResultModel.Order) {
        self.order.send(order)
    }
    
    func setSearchText(_ searchText: String?) {
        self.searchText.send(searchText)
    }
}

// MARK: - SettingModelFactory
extension ResultModel {
    func makeSettingModel() -> SettingModel {
        suspendAutoRefresh.send()
        return SettingModel(setting: setting.value,
                            settingSubscriber: AnySubscriber(setting),
                            cancelSubscriber: AnySubscriber(resumeAutoRefresh))
    }
}
