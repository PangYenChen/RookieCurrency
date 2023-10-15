import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored properties
    private let model: ResultModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        model = ResultModel()
        
        anyCancellableSet = Set<AnyCancellable>()
        
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
        
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        _ = model.order.receive(order)
    }
    
    override func updateState() {
        _ = model.updateState.receive()
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
        _ = model.searchText.receive(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        _ = model.searchText.receive(nil)
    }
}
