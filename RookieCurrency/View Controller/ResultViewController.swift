//
//  ResultViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/5.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class ResultTableViewController: UITableViewController {

    // MARK: - Property
    @IBOutlet private weak var latestUpdateTimeItem: UIBarButtonItem!
    
    var numberOfDay: Int
    
    var baseCurrency: Currency
    
    /// 分析過的匯率資料
    private var analyzedDataArray: Array<(currency: ResponseDataModel.RateList.Currency, latest: Double, mean: Double, deviation: Double)> = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        do { // numberOfDay
            let numberOfDayInUserDefaults = UserDefaults.standard.integer(forKey: "numberOfDay")
            let defaultNumberOfDay = 30
            numberOfDay = numberOfDayInUserDefaults > 0 ? numberOfDayInUserDefaults : defaultNumberOfDay
        }
        
        do { // baseCurrency
            if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
               let baseCurrency = ResponseDataModel.RateList.Currency(rawValue: baseCurrencyString) {
                self.baseCurrency = baseCurrency
            } else {
                baseCurrency = .TWD
            }
        }
        
        super.init(coder: coder)
        
        do { // search controller
            navigationItem.searchController = UISearchController()
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do { // latestUpdateTimeItem
            latestUpdateTimeItem.title = R.string.localizable.latestUpdateTime("-")
            latestUpdateTimeItem.tintColor = UIColor.label
            latestUpdateTimeItem.isEnabled = false
        }
        
        do { // table view
            let refreshControl = UIRefreshControl()
            tableView.refreshControl = refreshControl
            let handler = UIAction { [unowned self] _ in refresh() }
            refreshControl.addAction(handler, for: .primaryActionTriggered)
        }
        
        refresh()
    }
    
    private func refresh() {
        tableView.refreshControl?.beginRefreshing()
        
        RateListSetController.getRatesSetForDays(numberOfDay: numberOfDay) { [unowned self] result in
            switch result {
            case .success(let (latestRateList, historicalRateListSet)):
                
                do { // update latestUpdateTimeItem
                    let timestamp = Double(latestRateList.timestamp)
                    let date = Date(timeIntervalSince1970: timestamp)
                    let dateString = DateFormatter.uiDateFormatter.string(from: date)
                    latestUpdateTimeItem.title = R.string.localizable.latestUpdateTime(dateString)
                }
                
                analyzedDataArray = RateListSetAnalyst
                    .analyze(latestRateList: latestRateList,
                             historicalRateListSet: historicalRateListSet,
                             baseCurrency: baseCurrency)
                    .sorted { $0.value.deviation > $1.value.deviation }
                    .map { (currency: $0.key, latest: $0.value.latest, mean: $0.value.mean, $0.value.deviation)}
                
            case .failure(let error):
                //                self.showErrorAlert(error: error)
                break
            }
            
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    func refreshWith(baseCurrency: Currency, andNumberOfDay numberOfDay: Int) {
        #warning("有 side effect 要改名字，跟 refresh 整合")
        UserDefaults.standard.set(baseCurrency.rawValue, forKey: "baseCurrency")
        UserDefaults.standard.set(numberOfDay, forKey: "numberOfDay")
        
        refresh()
    }
    
    @IBSegueAction private func showSetting(_ coder: NSCoder) -> SettingNavigationController? {
        return SettingNavigationController(coder: coder, resultTableViewController: self)
    }
}

// MARK: - Table view data source
extension ResultTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return analyzedDataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
        
        let data = analyzedDataArray[indexPath.item]
        let currency = data.currency
        let deviationString = NumberFormatter.localizedString(from: NSNumber(value: data.deviation), number: .decimal)
        let meanString = NumberFormatter.localizedString(from: NSNumber(value: data.mean), number: .decimal)
        let latestString = NumberFormatter.localizedString(from: NSNumber(value: data.latest), number: .decimal)
        
        cell.textLabel?.text = "\(currency) " + currency.name + deviationString
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.textColor = data.deviation < 0 ? .systemGreen : .systemRed
        
        cell.detailTextLabel?.text = R.string.localizable.currencyCellDetail(meanString, latestString)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        
        return cell
    }
}
    
