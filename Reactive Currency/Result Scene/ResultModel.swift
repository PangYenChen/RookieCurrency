import Foundation
import Combine

final class ResultModel: BaseResultModel {
    // MARK: - initializer
    init(
        currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared,
        rateManager: RateManagerProtocol = RateManager.shared,
        userSettingManager: UserSettingManagerProtocol = UserSettingManager.shared,
        timer: TimerProtocol = TimerProxy()
    ) {
        var userSettingManager: UserSettingManagerProtocol = userSettingManager
        
        do /*initialize input*/ {
            setting = CurrentValueSubject((userSettingManager.numberOfDays,
                                           userSettingManager.baseCurrencyCode,
                                           userSettingManager.currencyCodeOfInterest))
            
            refreshTriggerByUser = PassthroughSubject<Void, Never>()
            
            searchText = CurrentValueSubject<String?, Never>(nil)
            
            order = CurrentValueSubject<BaseResultModel.Order, Never>(userSettingManager.resultOrder)
            
            resumeAutoRefresh = CurrentValueSubject<Void, Never>(())
            
            suspendAutoRefresh = PassthroughSubject<Void, Never>()
        }
        
        let settingFromSettingModel: AnyPublisher<Setting, Never> = setting.dropFirst().eraseToAnyPublisher()
        
        do /*initialize output*/ {
            let refresh: AnyPublisher<Void, Never>
            
            do /*initialize refresh*/ {
                let autoRefresh: AnyPublisher<Void, Never>
                
                do /*initialize autoRefresh*/ {
                    let timerPublisher: AnyPublisher<AnyPublisher<Void, Never>, Never> = Publishers
                        .Merge(resumeAutoRefresh,
                               settingFromSettingModel.map { _ in })
                        .map { _ in timer.makeTimerPublisher(every: Self.autoRefreshTimeInterval) }
                        .eraseToAnyPublisher()
                    
                    let emptyPublisher: AnyPublisher<AnyPublisher<Void, Never>, Never> = suspendAutoRefresh
                        .map { Empty<Void, Never>().eraseToAnyPublisher() }
                        .eraseToAnyPublisher()
                    
                    autoRefresh = Publishers.Merge(timerPublisher, emptyPublisher)
                        .switchToLatest()
                        .eraseToAnyPublisher()
                }
                
                refresh = Publishers.Merge(refreshTriggerByUser,
                                           autoRefresh)
                .eraseToAnyPublisher()
            }
            
            // TODO: rename to analysis 全域搜尋取代
            let analyzedResult: AnyPublisher<Result<AnalyzedSuccess, Error>, Never> = refresh.withLatestFrom(setting)
                .flatMap { _, setting in
                    rateManager
                        .ratePublisher(numberOfDays: setting.numberOfDays)
                        .convertOutputToResult()
                        .map { result in
                            result.map { rateTuple in
                                let analyzedDataArray: [BaseResultModel.AnalyzedData] = Analyst
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
            
            analyzedDataArray = analyzedResult.resultSuccess()
                .map { tuple in tuple.analyzedDataArray }
                .combineLatest(order, searchText) { analyzedDataArray, order, searchText in
                    Self.sort(analyzedDataArray,
                              by: order,
                              filteredIfNeededBy: searchText)
                }
                .eraseToAnyPublisher()
            
            error = analyzedResult.resultFailure()
            
            do /*initialize refreshStatus*/ {
                let refreshStatusProcess: AnyPublisher<BaseResultModel.RefreshStatus, Never> = refresh
                    .map { _ in .process }
                    .eraseToAnyPublisher()
                
                let refreshStatusIdle: AnyPublisher<BaseResultModel.RefreshStatus, Never> = analyzedResult
                    .scan(.idle(latestUpdateTimestamp: nil)) { partialResult, analyzedResult -> BaseResultModel.RefreshStatus in
                        switch analyzedResult {
                            case .success(let analyzedSuccess):
                                return .idle(latestUpdateTimestamp: analyzedSuccess.latestUpdateTime)
                            case .failure:
                                return partialResult
                        }
                    }
                    .eraseToAnyPublisher()
                
                refreshStatus = Publishers.Merge(refreshStatusProcess,
                                                 refreshStatusIdle)
                    .eraseToAnyPublisher()
            }
        }
        
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
    
    deinit {
        suspendAutoRefresh.send()
    }
    
    // MARK: - input properties
    /// 是 user setting 的一部份，要傳遞到 setting model 的資料，在那邊編輯
    private let setting: CurrentValueSubject<BaseResultModel.Setting, Never>
    
    /// 是 user setting 的一部份，跟 `setting` 不同的是，`order` 在這裡修改
    private let order: CurrentValueSubject<Order, Never>
    
    private let refreshTriggerByUser: PassthroughSubject<Void, Never>
    
    private let searchText: CurrentValueSubject<String?, Never>
    
    private let resumeAutoRefresh: CurrentValueSubject<Void, Never>
    
    private let suspendAutoRefresh: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: output properties
    let analyzedDataArray: AnyPublisher<[BaseResultModel.AnalyzedData], Never>
    
    let refreshStatus: AnyPublisher<BaseResultModel.RefreshStatus, Never>
    
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
                            saveSettingSubscriber: AnySubscriber(setting),
                            cancelSubscriber: AnySubscriber(resumeAutoRefresh))
    }
}

// MARK: - private name space
private extension ResultModel {
    typealias AnalyzedSuccess = (latestUpdateTime: Int, analyzedDataArray: [BaseResultModel.AnalyzedData])
}
