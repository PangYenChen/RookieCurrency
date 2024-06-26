import Foundation
import Combine

final class ResultModel: BaseResultModel {
    // MARK: - initializer
    init(userSettingManager: UserSettingManagerProtocol,
         rateManager: RateManagerProtocol,
         currencyDescriber: CurrencyDescriberProtocol,
         timer: TimerProtocol) {
        var userSettingManager: UserSettingManagerProtocol = userSettingManager
        
        do /*initialize input*/ {
            setting = CurrentValueSubject((userSettingManager.numberOfDays,
                                           userSettingManager.baseCurrencyCode,
                                           userSettingManager.currencyCodeOfInterest))
            
            refreshTriggerByUser = PassthroughSubject<Void, Never>()
            
            searchText = CurrentValueSubject<String?, Never>(nil)
            
            order = CurrentValueSubject<Order, Never>(userSettingManager.resultOrder)
            
            resumeAutoRefreshSubject = PassthroughSubject<Void, Never>()
            
            suspendAutoRefresh = PassthroughSubject<Void, Never>()
        }
        
        let settingFromSettingModel: AnyPublisher<Setting, Never> = setting.dropFirst().eraseToAnyPublisher()
        
        do /*initialize output*/ {
            let refresh: AnyPublisher<Void, Never>
            
            do /*initialize refresh*/ {
                let autoRefresh: AnyPublisher<Void, Never>
                
                do /*initialize autoRefresh*/ {
                    let timerPublisher: AnyPublisher<AnyPublisher<Void, Never>, Never> = Publishers
                        .Merge(resumeAutoRefreshSubject,
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
                
                refresh = Publishers
                    .Merge(refreshTriggerByUser,
                           autoRefresh)
                    .share()
                    .eraseToAnyPublisher()
            }
            
            let statisticsInfoTupleResult: AnyPublisher<Result<StatisticsInfoTuple, Error>, Never> = refresh
                .withLatestFrom(setting)
                .flatMap { _, setting in
                    rateManager
                        .ratePublisher(numberOfDays: setting.numberOfDays)
                        .convertOutputToResult()
                        .map { result in
                            result.map { rateTuple in
                                let statisticsInfo: StatisticsInfo = Self
                                    .statisticize(baseCurrencyCode: setting.baseCurrencyCode,
                                                  currencyCodeOfInterest: setting.currencyCodeOfInterest,
                                                  latestRate: rateTuple.latestRate,
                                                  historicalRateSet: rateTuple.historicalRateSet,
                                                  currencyDescriber: currencyDescriber)
                                return (latestUpdateTime: rateTuple.latestRate.timestamp,
                                        statisticsInfo: statisticsInfo)
                            }
                        }
                }
                .share()
                .eraseToAnyPublisher()
            
            let statisticsInfoTuple: AnyPublisher<StatisticsInfoTuple, Never> = statisticsInfoTupleResult
                .share()
                .resultFilterSuccess()
            
            rateStatistics = statisticsInfoTuple
                .map { statisticsInfoTuple in statisticsInfoTuple.statisticsInfo }
                .combineLatest(order, searchText) { statisticsInfo, order, searchText in
                    Self.sort(statisticsInfo.rateStatistics,
                              by: order,
                              filteredIfNeededBy: searchText)
                }
                .share()
                .eraseToAnyPublisher()
            
            dataAbsentCurrencyCodeSet = statisticsInfoTuple
                .map { rateStatisticsTuple in rateStatisticsTuple.statisticsInfo.dataAbsentCurrencyCodeSet }
                .filter { dataAbsentCurrencyCodeSet in !dataAbsentCurrencyCodeSet.isEmpty }
                .share()
                .eraseToAnyPublisher()
            
            error = statisticsInfoTupleResult
                .share()
                .resultFilterFailure()
            
            do /*initialize refreshStatus*/ {
                let refreshStatusProcess: AnyPublisher<RefreshStatus, Never> = refresh
                    .map { _ in .process }
                    .eraseToAnyPublisher()
                
                let refreshStatusIdle: AnyPublisher<RefreshStatus, Never> = statisticsInfoTupleResult
                    .scan(.idle(latestUpdateTimestamp: nil)) { partialResult, statisticsInfoTupleResult -> RefreshStatus in
                        switch statisticsInfoTupleResult {
                            case .success(let statisticsInfoTuple):
                                return .idle(latestUpdateTimestamp: statisticsInfoTuple.latestUpdateTime)
                            case .failure:
                                return partialResult
                        }
                    }
                    .eraseToAnyPublisher()
                
                refreshStatus = Publishers.Merge(refreshStatusProcess,
                                                 refreshStatusIdle)
                .share()
                .eraseToAnyPublisher()
            }
        }
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(userSettingManager: userSettingManager,
                   currencyDescriber: currencyDescriber)
        
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
    private let setting: CurrentValueSubject<Setting, Never>
    
    /// 是 user setting 的一部份，跟 `setting` 不同的是，`order` 在這裡修改
    private let order: CurrentValueSubject<Order, Never>
    
    private let refreshTriggerByUser: PassthroughSubject<Void, Never>
    
    private let searchText: CurrentValueSubject<String?, Never>
    
    private let resumeAutoRefreshSubject: PassthroughSubject<Void, Never>
    
    private let suspendAutoRefresh: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: output properties
    let rateStatistics: AnyPublisher<[RateStatistic], Never>
    
    let dataAbsentCurrencyCodeSet: AnyPublisher<Set<ResponseDataModel.CurrencyCode>, Never>
    
    let refreshStatus: AnyPublisher<RefreshStatus, Never>
    
    let error: AnyPublisher<Error, Never>
}

// MARK: - methods
extension ResultModel {
    func refresh() {
        refreshTriggerByUser.send()
    }
    
    func setOrder(_ order: Order) {
        self.order.send(order)
    }
    
    func setSearchText(_ searchText: String?) {
        self.searchText.send(searchText)
    }
    
    func resumeAutoRefresh() {
        resumeAutoRefreshSubject.send()
    }
}

// MARK: - SettingModelFactory
extension ResultModel {
    func makeSettingModel() -> SettingModel {
        suspendAutoRefresh.send()
        return SettingModel(setting: setting.value,
                            currencyDescriber: SupportedCurrencyManager.shared,
                            saveSettingSubscriber: AnySubscriber(setting),
                            cancelSubscriber: AnySubscriber(resumeAutoRefreshSubject))
    }
}

// MARK: - private name space
private extension ResultModel {
    typealias StatisticsInfoTuple = (latestUpdateTime: Int, statisticsInfo: StatisticsInfo)
}
