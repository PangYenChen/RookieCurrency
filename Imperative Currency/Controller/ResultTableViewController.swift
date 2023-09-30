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
        guard model.order != order else {
            return
        }
        model.order = order
        AppUtility.order = order
        sortingBarButtonItem.menu?.children.first?.subtitle = order.localizedName
//        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
//                          order: model.order,
//                          searchText: model.searchText)
#warning("還沒處理")
    }
    
//    override func getOrder() -> BaseResultModel.Order { model.order }
    
    override func refreshControlTriggered() {
        refreshDataAndPopulateTableView()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
//        tearDownTimer()
        
        return SettingTableViewController(coder: coder,
                                          numberOfDay: model.numberOfDay,
                                          baseCurrency: model.baseCurrency,
                                          currencyOfInterest: model.currencyOfInterest) { [unowned self] editedNumberOfDay, editedBaseCurrency, editedCurrencyOfInterest in
            // base currency
            do {
                model.baseCurrency = editedBaseCurrency
                AppUtility.baseCurrency = model.baseCurrency
            }
            
            // number Of Day
            do {
                model.numberOfDay = editedNumberOfDay
                AppUtility.numberOfDay = model.numberOfDay
            }
            
            // currency of interest
            do {
                model.currencyOfInterest = editedCurrencyOfInterest
                AppUtility.currencyOfInterest = model.currencyOfInterest
            }
            
            refreshDataAndPopulateTableView()
        } cancelCompletionHandler: { [unowned self] in
//            setUpTimer()
        }
    }
}

private extension ResultTableViewController {
    
//    func setUpTimer() {
//        timer = Timer.scheduledTimer(withTimeInterval: autoRefreshTimeInterval, repeats : true) { [unowned self] _ in
//            refreshDataAndPopulateTableView()
//        }
//    }
//    
//    func tearDownTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
    /// 更新資料並且填入 table view
    func refreshDataAndPopulateTableView() {
        
//        tearDownTimer()
        
        if refreshControl?.isRefreshing == false {
            refreshControl?.beginRefreshing()
        }
        
        updatingStatusBarButtonItem.title = R.string.resultScene.updating()
        
        model.updateData(numberOfDays: model.numberOfDay) { [unowned self] result in
            switch result {
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
//            switch result {
//            case .success(let (latestRate, historicalRateSet)):
//                
//                // update latestUpdateTime
//                do {
//                    let timestamp = Double(latestRate.timestamp)
//                    model.latestUpdateTime = Date(timeIntervalSince1970: timestamp)
//                }
//                
//                // update table view
//                do {
//                    let analyzedResult = Analyst
//                        .analyze(currencyOfInterest: model.currencyOfInterest,
//                                 latestRate: latestRate,
//                                 historicalRateSet: historicalRateSet,
//                                 baseCurrency: model.baseCurrency)
//                    
//                    let analyzedErrors = analyzedResult
//                        .filter { _, result in
//                            switch result {
//                            case .failure: return true
//                            case .success: return false
//                            }
//                        }
//                    
//                    if analyzedErrors.isEmpty {
//                        analyzedDataDictionary = analyzedResult
//                            .compactMapValues { result in try? result.get() }
//                        
//                        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
//                                          order: model.order,
//                                          searchText: model.searchText)
////                        setUpTimer()
//                    } else {
//                        analyzedErrors.keys
//                        #warning("這邊要present alert，告知使用者要刪掉本地資料，全部重拿")
//                    }
//                }
//                
//            case .failure(let error):
//                presentAlert(error: error) { [unowned self] _ in
////                    setUpTimer()
//                }
//            }
//            
//            do { // update updatingStatusItem
//                let dateString = model.latestUpdateTime?.formatted(.relative(presentation: .named)) ?? "-"
//                updatingStatusItem.title = R.string.resultScene.latestUpdateTime(dateString)
//            }
//            
//            refreshControl?.endRefreshing()
        }
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard model.searchText != searchText else {
            return
        }
        model.searchText = searchText
//        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
//                          order: model.order,
//                          searchText: model.searchText)
        #warning("還沒處理")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        model.searchText = ""
//        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
//                          order: model.order,
//                          searchText: model.searchText)
#warning("還沒處理")
    }
}


