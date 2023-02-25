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
    
    private var baseCurrency: Currency
    
    private var order: Order
    
    private var searchText: String
    
    private var latestUpdateTime: Date?
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        numberOfDay = UserDefaults.numberOfDay
        baseCurrency = UserDefaults.baseCurrency
        order = UserDefaults.order
        searchText = String()
        latestUpdateTime =  nil
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        latestUpdateTimeItem.title = R.string.localizable.latestUpdateTime("-")
        
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
                                   baseCurrency: baseCurrency) { [unowned self] editedNumberOfDay, editedBaseCurrency in
            // base currency
            do {
                baseCurrency = editedBaseCurrency
                UserDefaults.baseCurrency = baseCurrency
            }
            
            // number Of Day
            do {
                numberOfDay = editedNumberOfDay
                UserDefaults.numberOfDay = numberOfDay
            }
            
            refreshDataAndPopulateTableView()
        }
    }
    
    /// 更新資料並且填入 table view
    private func refreshDataAndPopulateTableView() {
        if refreshControl?.isRefreshing == false {
            refreshControl?.beginRefreshing()
        }

        latestUpdateTimeItem.title = R.string.localizable.updating()

        RateListController.shared.getRatesSetForDays(numberOfDay: numberOfDay) { [unowned self] result in
            switch result {
            case .success(let (latestRateList, historicalRateListSet)):
                
                // update latestUpdateTime
                do {
                    let timestamp = Double(latestRateList.timestamp)
                    latestUpdateTime = Date(timeIntervalSince1970: timestamp)
                }

                // update table view
                do {
                    analyzedDataDictionary = RateListSetAnalyst
                        .analyze(latestRateList: latestRateList,
                                 historicalRateListSet: historicalRateListSet,
                                 baseCurrency: baseCurrency)
                    populateTableView(analyzedDataDictionary: self.analyzedDataDictionary,
                                      order: self.order,
                                      searchText: self.searchText)
                }

            case .failure(let error):
                showErrorAlert(error: error)
            }

            do { // update latestUpdateTimeItem
                let dateString = latestUpdateTime.map(DateFormatter.uiDateFormatter.string(from:)) ?? "-"
                latestUpdateTimeItem.title = R.string.localizable.latestUpdateTime(dateString)
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


