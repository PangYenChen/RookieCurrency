import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored properties
    private let model: ResultModel
    
    private let order: PassthroughSubject<ResultModel.Order, Never>
    private let searchText: PassthroughSubject<String?, Never>
    private let updateModelState: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    private var latestUpdateTime: Int?
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        model = ResultModel()
        
        order = PassthroughSubject<ResultModel.Order, Never>()
        order.receive(subscriber: model.order)
        
        searchText = PassthroughSubject<String?, Never>()
        searchText.receive(subscriber: model.searchText)
        
        updateModelState = PassthroughSubject<Void, Never>()
        updateModelState.receive(subscriber: model.updateState)
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, initialOrder: model.initialOrder)
    }
    
    required init?(coder: NSCoder, initialOrder: BaseResultModel.Order) {
        fatalError("init(coder:initialOrder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.state
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] state in
                switch state {
                case .updating:
                    updatingStatusBarButtonItem.title = R.string.resultScene.updating()
                case .updated(let timestamp, let analyzedDataArray):
                    self.latestUpdateTime = timestamp
                    populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
                    populateTableViewWith(analyzedDataArray)
                    
                    if tableView.refreshControl?.isRefreshing == true {
                        tableView.refreshControl?.endRefreshing()
                    }
                    
                case .failure(let error):
                    populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
                    presentAlert(error: error)
                    
                    if tableView.refreshControl?.isRefreshing == true {
                        tableView.refreshControl?.endRefreshing()
                    }
                }
            }
            .store(in: &anyCancellableSet)
        
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        self.order.send(order)
    }
    
    override func updateState() {
        self.updateModelState.send()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        //        tearDownTimer()
        
        let timerTearDownSubject = PassthroughSubject<Void, Never>()
        //        timerCancellable = timerTearDownSubject.sink { [unowned self] _ in setUpTimer() }
        
        return SettingTableViewController(coder: coder,
                                          userSetting: model.userSetting.value,
                                          settingSubscriber: AnySubscriber(model.userSetting),
                                          cancelSubscriber: AnySubscriber(timerTearDownSubject))
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchText.send(nil)
    }
}
