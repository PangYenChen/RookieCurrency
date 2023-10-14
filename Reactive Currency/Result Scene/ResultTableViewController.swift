import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored properties
    private let model: ResultModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    private var timerCancellable: AnyCancellable?
    
    private var timerTearDownCancellable: AnyCancellable?
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        model = ResultModel()
    
        anyCancellableSet = Set<AnyCancellable>()
        timerCancellable = nil
        
        super.init(coder: coder, initialOrder: model.initialOrder)
    }
    
    required init?(coder: NSCoder, initialOrder: BaseResultModel.Order) {
        fatalError("init(coder:initialOrder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.state
            .sink { [unowned self] state in
                switch state {
                case .updating:
                    updatingStatusBarButtonItem.title = R.string.resultScene.updating()
                case .updated(let timestamp, let analyzedDataArray):
//                    self.latestUpdateTime = timestamp
//                    populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
                    populateTableViewWith(analyzedDataArray)
                    
                    if tableView.refreshControl?.isRefreshing == true {
                        tableView.refreshControl?.endRefreshing()
                    }
                    
                case .failure(let error):
//                    populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
                    presentAlert(error: error)
                    
                    if tableView.refreshControl?.isRefreshing == true {
                        tableView.refreshControl?.endRefreshing()
                    }
                }
            }
            .store(in: &anyCancellableSet)
        // send initial value
        do {
            
//            model.searchText.send("")
            model.refresh.send()
        }
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        model.order.send(order)
    }
    
    override func requestDataFromModel() {
        #warning("還沒實作")
        super.requestDataFromModel()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        tearDownTimer()
        
        let timerTearDownSubject = PassthroughSubject<Void, Never>()
        timerCancellable = timerTearDownSubject.sink { [unowned self] _ in setUpTimer() }
        
        return SettingTableViewController(coder: coder,
                                          userSetting: model.userSetting.value,
                                          settingSubscriber: AnySubscriber(model.userSetting),
                                          cancelSubscriber: AnySubscriber(timerTearDownSubject))
    }
}

// MARK: - private methods
private extension ResultTableViewController {
    func setUpTimer() {
//        timerCancellable = Timer.publish(every: autoRefreshTimeInterval, on: .main, in: .default)
//            .autoconnect()
//            .sink { [unowned self] _ in refresh.send() }
    }
    
    func tearDownTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        model.searchText.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        model.searchText.send("")
    }
}
