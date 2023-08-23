//
//  ResultTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/5.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class ResultTableViewController: BaseResultTableViewController {
    
    // MARK: - stored properties
    private var numberOfDay: Int
    
    private var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    private var baseCurrency: ResponseDataModel.CurrencyCode
    
    private var order: Order
    
    private var searchText: String
    
    private var latestUpdateTime: Date?
    
    private var timer: Timer?
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        
        numberOfDay = AppUtility.numberOfDay
        baseCurrency = AppUtility.baseCurrency
        currencyOfInterest = Set(AppUtility.currencyOfInterest)
        order = AppUtility.order
        searchText = String()
        latestUpdateTime =  nil
        timer = nil
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updatingStatusItem.title = R.string.localizable.latestUpdateTime("-")
        
        refreshDataAndPopulateTableView()
    }
    
    // MARK: - Hook methods
    override func setOrder(_ order: BaseResultTableViewController.Order) {
        guard self.order != order else {
            return
        }
        self.order = order
        AppUtility.order = order
        sortItem.menu?.children.first?.subtitle = order.localizedName
        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
                          order: self.order,
                          searchText: self.searchText)
    }
    
    override func getOrder() -> BaseResultTableViewController.Order { order }
    
    override func refreshControlTriggered() {
        refreshDataAndPopulateTableView()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        tearDownTimer()
        
        return SettingTableViewController(coder: coder,
                                          numberOfDay: numberOfDay,
                                          baseCurrency: baseCurrency,
                                          currencyOfInterest: currencyOfInterest) { [unowned self] editedNumberOfDay, editedBaseCurrency, editedCurrencyOfInterest in
            // base currency
            do {
                baseCurrency = editedBaseCurrency
                AppUtility.baseCurrency = baseCurrency
            }
            
            // number Of Day
            do {
                numberOfDay = editedNumberOfDay
                AppUtility.numberOfDay = numberOfDay
            }
            
            // currency of interest
            do {
                currencyOfInterest = editedCurrencyOfInterest
                AppUtility.currencyOfInterest = currencyOfInterest
            }
            
            refreshDataAndPopulateTableView()
        } cancelCompletionHandler: { [unowned self] in
            setUpTimer()
        }
    }
}

private extension ResultTableViewController {
    
    func setUpTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: autoRefreshTimeInterval, repeats : true) { [unowned self] _ in
            refreshDataAndPopulateTableView()
        }
    }
    
    func tearDownTimer() {
        timer?.invalidate()
        timer = nil
    }
    /// 更新資料並且填入 table view
    func refreshDataAndPopulateTableView() {
        
        tearDownTimer()
        
        if refreshControl?.isRefreshing == false {
            refreshControl?.beginRefreshing()
        }
        
        updatingStatusItem.title = R.string.localizable.updating()
        
        RateController.shared.getRateFor(numberOfDays: numberOfDay, completionHandlerQueue: .main) { [unowned self] result in
            switch result {
            case .success(let (latestRate, historicalRateSet)):
                
                // update latestUpdateTime
                do {
                    let timestamp = Double(latestRate.timestamp)
                    latestUpdateTime = Date(timeIntervalSince1970: timestamp)
                }
                
                // update table view
                do {
                    let analyzedResult = Analyst
                        .analyze(currencyOfInterest: currencyOfInterest,
                                 latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrency: baseCurrency)
                    
                    let analyzedErrors = analyzedResult
                        .filter { _, result in
                            switch result {
                            case .failure: return true
                            case .success: return false
                            }
                        }
                    
                    if analyzedErrors.isEmpty {
                        analyzedDataDictionary = analyzedResult
                            .compactMapValues { result in try? result.get() }
                        
                        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
                                          order: self.order,
                                          searchText: self.searchText)
                        setUpTimer()
                    } else {
                        analyzedErrors.keys
                        #warning("這邊要present alert，告知使用者要刪掉本地資料，全部重拿")
                    }
                }
                
            case .failure(let error):
                presentAlert(error: error) { [unowned self] _ in
                    setUpTimer()
                }
            }
            
            do { // update updatingStatusItem
                let dateString = latestUpdateTime?.formatted(.relative(presentation: .named)) ?? "-"
                updatingStatusItem.title = R.string.localizable.latestUpdateTime(dateString)
            }
            
            refreshControl?.endRefreshing()
        }
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard self.searchText != searchText else {
            return
        }
        self.searchText = searchText
        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
                          order: self.order,
                          searchText: self.searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText = ""
        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
                          order: self.order,
                          searchText: self.searchText)
    }
}

