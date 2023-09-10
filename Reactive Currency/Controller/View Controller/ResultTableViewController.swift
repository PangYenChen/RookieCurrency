import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    
    // MARK: - stored properties
    private let userSetting: CurrentValueSubject<UserSetting, Never>
    
    private let order: CurrentValueSubject<Order, Never>
    
    private let searchText: PassthroughSubject<String, Never>
    
    private let refresh: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    private var timerCancellable: AnyCancellable?
    
    private var timerTearDownCancellable: AnyCancellable?
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        userSetting = CurrentValueSubject((AppUtility.numberOfDay, AppUtility.baseCurrency, AppUtility.currencyOfInterest))
        order = CurrentValueSubject<Order, Never>(AppUtility.order)
        searchText = PassthroughSubject<String, Never>()
        refresh = PassthroughSubject<Void, Never>()
        anyCancellableSet = Set<AnyCancellable>()
        timerCancellable = nil
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // subscribe
        do {
            order
                .dropFirst()
                .removeDuplicates()
                .sink { [unowned self] order in
                    AppUtility.order = order
                    sortItem.menu?.children.first?.subtitle = order.localizedName
                }
                .store(in: &anyCancellableSet)
            
            userSetting
                .dropFirst()
                .sink { numberOfDay, baseCurrency, currencyOfInterest in
                    AppUtility.numberOfDay = numberOfDay
                    AppUtility.baseCurrency = baseCurrency
                    AppUtility.currencyOfInterest = currencyOfInterest
                }
                .store(in: &anyCancellableSet)
            
            userSetting
                .sink { [unowned self] _ in
                    refreshControl?.beginRefreshing()
                    tearDownTimer()
                }
                .store(in: &anyCancellableSet)
            
            let updating = Publishers.CombineLatest(refresh, userSetting).share()
            
            let rateSetResult = updating
                .handleEvents(receiveOutput: { [unowned self] _ in tearDownTimer() })
                .flatMap { _, numberOfDayAndBaseCurrency in
                    RateController.shared
                        .ratePublisher(numberOfDay: numberOfDayAndBaseCurrency.numberOfDay)
                        .convertOutputToResult()
                        .receive(on: DispatchQueue.main)
                }
                .share()
            
            let isUpdating = Publishers.Merge(updating.map { _ in true },
                                              rateSetResult.map { _ in false } )
            
            let rateSetFailure = rateSetResult
                .resultFailure()
                .share()
            
            rateSetFailure
                .sink { [unowned self] failure in presentAlert(error: failure, handler: { [unowned self] _ in setUpTimer() }) }
                .store(in: &anyCancellableSet)
            
            let rateSetSuccess = rateSetResult
                .resultSuccess()
                .share()
            
            let latestUpdateTimeString = rateSetSuccess
                .map { rateSet in rateSet.latestRate.timestamp }
                .map(Double.init)
                .map(Date.init(timeIntervalSince1970:))
                .map { $0.formatted(.relative(presentation: .named)) }
                .prepend("-")
                .map { R.string.resultScene.latestUpdateTime($0) }
            
            let updateSuccessTimeString = latestUpdateTimeString
            
            Publishers
                .CombineLatest(isUpdating, latestUpdateTimeString)
                .sink { [unowned self] isUpdating, latestUpdateTimeString in
                    updatingStatusItem.title = isUpdating ? R.string.resultScene.updating() : latestUpdateTimeString
                }
                .store(in: &anyCancellableSet)
            
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
                                                                    order.removeDuplicates(),
                                                                    searchText.removeDuplicates())
                .share()
            
            shouldPopulateTableView
                .sink { [unowned self] analyzedDataDictionary, order, searchText  in
                    self.analyzedDataDictionary = analyzedDataDictionary
                    populateTableView(analyzedDataDictionary: analyzedDataDictionary,
                                      order: order,
                                      searchText: searchText)
                    setUpTimer()
                }
                .store(in: &anyCancellableSet)
            
            let shouldEndRefreshingControl = Publishers.Merge(rateSetFailure.map { _ in () },
                                                              shouldPopulateTableView.map { _ in () })
            
            shouldEndRefreshingControl
                .sink { [unowned self] _ in refreshControl?.endRefreshing() }
                .store(in: &anyCancellableSet)
        }
        
        // send initial value
        do {
            
            searchText.send("")
            refresh.send()
        }
    }
    
    override func setOrder(_ order: BaseResultTableViewController.Order) {
        self.order.send(order)
    }
    
    override func getOrder() -> BaseResultTableViewController.Order {
        order.value
    }
    
    override func refreshControlTriggered() {
        refresh.send()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        tearDownTimer()
        
        let timerTearDownSubject = PassthroughSubject<Void, Never>()
        timerCancellable = timerTearDownSubject.sink { [unowned self] _ in setUpTimer() }
        
        return SettingTableViewController(coder: coder,
                                          userSetting: userSetting.value,
                                          settingSubscriber: AnySubscriber(userSetting),
                                          cancelSubscriber: AnySubscriber(timerTearDownSubject))
    }
}

// MARK: - private methods
private extension ResultTableViewController {
    func setUpTimer() {
        timerCancellable = Timer.publish(every: autoRefreshTimeInterval, on: .main, in: .default)
            .autoconnect()
            .sink { [unowned self] _ in refresh.send() }
    }
    
    func tearDownTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText.send("")
    }
}
