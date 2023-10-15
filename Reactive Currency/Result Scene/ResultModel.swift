import Foundation
import Combine

class ResultModel: BaseResultModel {
#warning("要修改 access control")
    // MARK: - input
    let userSetting: CurrentValueSubject<BaseResultModel.UserSetting, Never>
    
    let order: AnySubscriber<Order, Never>
    
    let searchText: AnySubscriber<String?, Never>
    
    let updateState: AnySubscriber<Void, Never>
    
    // MARK: - output
    
    let state: AnyPublisher<State, Never>
    
    
    #warning("還沒實作自動更新")
    
    override init() {
        userSetting = CurrentValueSubject((AppUtility.numberOfDays, AppUtility.baseCurrencyCode, AppUtility.currencyCodeOfInterest))
        
        let orderPublisher = CurrentValueSubject<BaseResultModel.Order, Never>(AppUtility.order)
        order = AnySubscriber(orderPublisher)
        
        let searchTextPublisher = CurrentValueSubject<String?, Never>(nil)
        searchText = AnySubscriber(searchTextPublisher)
        
        let updateStatePublisher = CurrentValueSubject<Void, Never>(())
        updateState = AnySubscriber(updateStatePublisher)
        
        //
        
        do {
            
//            model.userSetting
//                .sink { [unowned self] _ in
//                    refreshControl?.beginRefreshing()
//                    tearDownTimer()
//                }
//                .store(in: &anyCancellableSet)
            
            let updating = Publishers.CombineLatest(updateStatePublisher, userSetting).share()
            
            let rateSetResult = updating
//                .handleEvents(receiveOutput: { [unowned self] _ in tearDownTimer() })
                .flatMap { _, numberOfDayAndBaseCurrency in
                    RateController.shared
                        .ratePublisher(numberOfDay: numberOfDayAndBaseCurrency.numberOfDay)
                        .convertOutputToResult()
                        .receive(on: DispatchQueue.main) // 要想一下這行要放哪 應該是 view controller，因為model只有業務邏輯，沒有UI的概念
                }
                .share()
            
//            let isUpdating = Publishers.Merge(updating.map { _ in true },
//                                              rateSetResult.map { _ in false } )
            
//            let rateSetFailure = rateSetResult
//                .resultFailure()
//                .share()
            
//            rateSetFailure
//                .sink { [unowned self] failure in presentAlert(error: failure, handler: { [unowned self] _ in setUpTimer() }) }
//                .store(in: &anyCancellableSet)
            
            let rateSetSuccess = rateSetResult
                .resultSuccess()
                .share()
            
//            let latestUpdateTimeString = rateSetSuccess
//                .map { rateSet in rateSet.latestRate.timestamp }
//                .map(Double.init)
//                .map(Date.init(timeIntervalSince1970:))
//                .map { $0.formatted(.relative(presentation: .named)) }
//                .prepend("-")
//                .map { R.string.resultScene.latestUpdateTime($0) }
            
//            let updateSuccessTimeString = latestUpdateTimeString
            
//            Publishers
//                .CombineLatest(isUpdating, latestUpdateTimeString)
//                .sink { [unowned self] isUpdating, latestUpdateTimeString in
//                    updatingStatusBarButtonItem.title = isUpdating ? R.string.resultScene.updating() : latestUpdateTimeString
//                }
//                .store(in: &anyCancellableSet)
            
            let analyzedDataDictionary = rateSetSuccess
                .withLatestFrom(userSetting)
                .map { rateSet, userSetting in
                    return Analyst.analyze(currencyOfInterest: userSetting.currencyOfInterest,
                                           latestRate: rateSet.latestRate,
                                           historicalRateSet: rateSet.historicalRateSet,
                                           baseCurrency: userSetting.baseCurrency)
                    .compactMapValues { result in try? result.get() }
#warning("還沒處理錯誤，要提示使用者即將刪掉本地的資料，重新從網路上拿")
                }
            
            let shouldPopulateTableView = Publishers.CombineLatest3(analyzedDataDictionary,
                                                                    orderPublisher.removeDuplicates(),
                                                                    searchTextPublisher.removeDuplicates())
                .share()
            
            state = shouldPopulateTableView
                .map { analyzedDataDictionary, order, searchText in
                    var analyzedDataArray = analyzedDataDictionary
                        .map { tuple in
                            AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                        }
                    analyzedDataArray = Self.sort(analyzedDataArray,
                                                  by: order,
                                                  filteredIfNeededBy: searchText)
                    
                    return .updated(timestamp: 0, analyzedDataArray: analyzedDataArray)
                }
                .eraseToAnyPublisher()
            
//            shouldPopulateTableView
//                .sink { [unowned self] analyzedDataDictionary, order, searchText  in
//                    //                    self.analyzedDataDictionary = analyzedDataDictionary
//                    //                    populateTableView(analyzedDataDictionary: analyzedDataDictionary,
//                    //                                      order: order,
//                    //                                      searchText: searchText)
//                    setUpTimer()
//                }
//                .store(in: &anyCancellableSet)
            
//            let shouldEndRefreshingControl = Publishers.Merge(rateSetFailure.map { _ in () },
//                                                              shouldPopulateTableView.map { _ in () })
            
//            shouldEndRefreshingControl
//                .sink { [unowned self] _ in refreshControl?.endRefreshing() }
//                .store(in: &anyCancellableSet)
        }
        
        super.init()
        
        #warning("要存 app utility")
        
    }
}
