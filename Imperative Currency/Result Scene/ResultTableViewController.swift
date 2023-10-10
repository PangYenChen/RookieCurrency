import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored property
    private let model: ResultModel
    
    private var latestUpdateTime: Int?
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        model = ResultModel()
        latestUpdateTime = nil
        
        super.init(coder: coder, initialOrder: model.initialOrder)
    }
    
    required init?(coder: NSCoder, initialOrder: BaseResultModel.Order) {
        fatalError("init(coder:initialOrder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestDataFromModel()
    }
    
    // MARK: - Hook methods
    override func setOrder(_ order: BaseResultModel.Order) {
        sortingBarButtonItem.menu?.children.first?.subtitle = order.localizedName
        populateTableViewWith(model.setOrderAndSortAnalyzedDataArray(order: order))
    }
    
    override func requestDataFromModel() {
        model.updateState() { [unowned self] result in
            switch result {
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
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        SettingTableViewController(coder: coder,
                                   numberOfDay: model.numberOfDays,
                                   baseCurrency: model.baseCurrencyCode,
                                   currencyOfInterest: model.currencyCodeOfInterest) { [unowned self] editedNumberOfDay, editedBaseCurrency, editedCurrencyOfInterest in
            model.updateStateFor(numberOfDays: editedNumberOfDay,
                                 baseCurrencyCode: editedBaseCurrency,
                                 currencyOfInterest: editedCurrencyOfInterest) { [unowned self] result in
                switch result {
                case .updating:
                    updatingStatusBarButtonItem.title = R.string.resultScene.updating()
                    
                case .updated(let timestamp, let analyzedDataArray):
                    self.latestUpdateTime = timestamp
                    populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
                    populateTableViewWith(analyzedDataArray)
                    
                case .failure(let error):
                    populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
                    presentAlert(error: error)
                }
            }
        } cancelCompletionHandler: { [unowned self] in
            //            setUpTimer()
        }
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        populateTableViewWith(model.setSearchTextAndFilterAnalyzedDataArray(searchText: searchText))
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        populateTableViewWith(model.setSearchTextAndFilterAnalyzedDataArray(searchText: nil))
    }
}
