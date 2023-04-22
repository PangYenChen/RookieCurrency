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
    
    private var baseCurrency: ResponseDataModel.CurrencyCode
    
    private var order: Order
    
    private var searchText: String
    
    private var latestUpdateTime: Date?
    
    private var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        numberOfDay = AppUtility.numberOfDay
        baseCurrency = AppUtility.baseCurrency
        order = AppUtility.order
        searchText = String()
        latestUpdateTime =  nil
        currencyOfInterest = Set(AppUtility.currencyOfInterest)
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updatingStatusItem.title = R.string.localizable.latestUpdateTime("-")
        
        // sort Item
        do {
            let increasingAction = UIAction(title: Order.increasing.localizedName,
                                            image: UIImage(systemName: "arrow.up.right"),
                                            handler: { [unowned self] _ in setOrder(.increasing) })
            let decreasingAction = UIAction(title: Order.decreasing.localizedName,
                                            image: UIImage(systemName: "arrow.down.right"),
                                            handler: { [unowned self] _ in setOrder(.decreasing) })
            
            switch order {
            case .increasing:
                increasingAction.state = .on
            case .decreasing:
                decreasingAction.state = .on
            }
            
            let sortMenu = UIMenu(title: R.string.localizable.sortedBy(),
                                  subtitle: order.localizedName,
                                  image: UIImage(systemName: "arrow.up.arrow.down"),
                                  options: .singleSelection,
                                  children: [increasingAction, decreasingAction])
            
            sortItem.menu = UIMenu(title: "",
                                   options: .singleSelection,
                                   children: [sortMenu])
        }
        
        refreshDataAndPopulateTableView()
    }
    
    override func setOrder(_ order: BaseResultTableViewController.Order) {
        self.order = order
        AppUtility.order = order
        sortItem.menu?.children.first?.subtitle = order.localizedName
        populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
                          order: self.order,
                          searchText: self.searchText)
    }
    
    override func refreshControlTriggered() {
        refreshDataAndPopulateTableView()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        SettingTableViewController(coder: coder,
                                   numberOfDay: numberOfDay,
                                   baseCurrency: baseCurrency,
                                   currencyOfInterest: currencyOfInterest) { [unowned self] editedNumberOfDay, editedBaseCurrency in
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
            
            refreshDataAndPopulateTableView()
        }
    }
    
    /// 更新資料並且填入 table view
    private func refreshDataAndPopulateTableView() {
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
                    analyzedDataDictionary = Analyst
                        .analyze(latestRate: latestRate,
                                 historicalRateSet: historicalRateSet,
                                 baseCurrency: baseCurrency)
                    populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
                                      order: self.order,
                                      searchText: self.searchText)
                }
                
            case .failure(let error):
                presentErrorAlert(error: error)
            }
            
            do { // update updatingStatusItem
                let dateString = latestUpdateTime?.formatted(date: .omitted, time: .standard) ?? "-"
                updatingStatusItem.title = R.string.localizable.latestUpdateTime(dateString)
            }
            
            refreshControl?.endRefreshing()
        }
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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


