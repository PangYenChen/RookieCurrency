import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updatingStatusBarButtonItem.title = R.string.resultScene.latestUpdateTime("-")
        
        refreshDataAndPopulateTableView()
    }
    
    // MARK: - Hook methods
    override func setOrder(_ order: BaseResultModel.Order) {
        model.updateDataFor(order: order) { [unowned self] state in
            switch state {
            case .initialized:
                break
            case .updating:
                updatingStatusBarButtonItem.title = R.string.resultScene.updating()
            case .updated(let time, let analyzedDataArray):
                do {
                    let timestamp = Double(time)
                    let latestUpdateDate = Date(timeIntervalSince1970: timestamp)
                    let dateString = latestUpdateDate.formatted(.relative(presentation: .named))
                    updatingStatusBarButtonItem.title = R.string.resultScene.latestUpdateTime(dateString)
#warning("第一次更新失敗沒有處理")
                    populateTableViewWith(analyzedDataArray: analyzedDataArray)
                }
            case .failure(let error):
                presentAlert(error: error)
            }
        }
    }
    
    override func refreshControlTriggered() {
        refreshDataAndPopulateTableView()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        return SettingTableViewController(coder: coder,
                                          numberOfDay: model.numberOfDay,
                                          baseCurrency: model.baseCurrency,
                                          currencyOfInterest: model.currencyOfInterest) { [unowned self] editedNumberOfDay, editedBaseCurrency, editedCurrencyOfInterest in
            model.updateDataFor(numberOfDays: editedNumberOfDay,
                                baseCurrencyCode: editedBaseCurrency,
                                currencyOfInterest: editedCurrencyOfInterest) { [unowned self] result in
                switch result {
                case .initialized:
                    break
                case .updating:
                    updatingStatusBarButtonItem.title = R.string.resultScene.updating()
                case .updated(let time, let analyzedDataArray):
                    do {
                        let timestamp = Double(time)
                        let latestUpdateDate = Date(timeIntervalSince1970: timestamp)
                        let dateString = latestUpdateDate.formatted(.relative(presentation: .named))
                        updatingStatusBarButtonItem.title = R.string.resultScene.latestUpdateTime(dateString)
#warning("第一次更新失敗沒有處理")
                        populateTableViewWith(analyzedDataArray: analyzedDataArray)
                    }
                case .failure(let error):
                    presentAlert(error: error)
                }
            }
        } cancelCompletionHandler: { [unowned self] in
//            setUpTimer()
        }
    }
}

private extension ResultTableViewController {
    
    /// 更新資料並且填入 table view
    func refreshDataAndPopulateTableView() {
        if refreshControl?.isRefreshing == false {
            refreshControl?.beginRefreshing()
        }
        
        updatingStatusBarButtonItem.title = R.string.resultScene.updating()
        
        model.updateData(numberOfDays: model.numberOfDay) { [unowned self] result in
            switch result {
            case .initialized:
                break
            case .updating:
                updatingStatusBarButtonItem.title = R.string.resultScene.updating()
            case .updated(let time, let analyzedDataArray):
                do {
                    let timestamp = Double(time)
                    let latestUpdateDate = Date(timeIntervalSince1970: timestamp)
                    let dateString = latestUpdateDate.formatted(.relative(presentation: .named))
                    updatingStatusBarButtonItem.title = R.string.resultScene.latestUpdateTime(dateString)
                    #warning("第一次更新失敗沒有處理")
                    populateTableViewWith(analyzedDataArray: analyzedDataArray)
                }
            case .failure(let error):
                presentAlert(error: error)
            }
        }
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        model.updateDataFor(searchText: searchText, completionHandler: updateUIWithSearchTextFor(state:))
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        model.updateDataFor(searchText: nil, completionHandler: updateUIWithSearchTextFor(state:))
    }
}

private extension ResultTableViewController {
    func updateUIWithSearchTextFor(state: BaseResultModel.State) {
        switch state {
        case .initialized:
            break
        case .updating:
            updatingStatusBarButtonItem.title = R.string.resultScene.updating()
        case .updated(let time, let analyzedDataArray):
            do {
                let timestamp = Double(time)
                let latestUpdateDate = Date(timeIntervalSince1970: timestamp)
                let dateString = latestUpdateDate.formatted(.relative(presentation: .named))
                updatingStatusBarButtonItem.title = R.string.resultScene.latestUpdateTime(dateString)
#warning("第一次更新失敗沒有處理")
                populateTableViewWith(analyzedDataArray: analyzedDataArray)
            }
        case .failure(let error):
            presentAlert(error: error)
        }
    }
}


