//
//  ResultViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/5.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class ResultTableViewController: UITableViewController {

    // MARK: - IBOutlet
    @IBOutlet private weak var latestUpdateTimeItem: UIBarButtonItem!
    
    // MARK: - stored properties
    private(set) var numberOfDay: Int
    
    private(set) var baseCurrency: Currency
    
    private var searchText: String
    
    /// 分析過的匯率資料
    private var analyzedDataDictionary: [Currency: (latest: Double, mean: Double, deviation: Double)]
    
    private var dataSource: DataSource!
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        do { // numberOfDay
            let numberOfDayInUserDefaults = UserDefaults.standard.integer(forKey: "numberOfDay")
            let defaultNumberOfDay = 30
            numberOfDay = numberOfDayInUserDefaults > 0 ? numberOfDayInUserDefaults : defaultNumberOfDay
        }
        
        do { // baseCurrency
            if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
               let baseCurrency = Currency(rawValue: baseCurrencyString) {
                self.baseCurrency = baseCurrency
            } else {
                baseCurrency = .TWD
            }
        }
        
        do { // search Text
            searchText = String()
        }
        
        do { // analyzed data
            analyzedDataDictionary = [:]
        }
        super.init(coder: coder)
        
        do { // search controller
            let searchController = UISearchController()
            searchController.searchBar.delegate = self
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            
        }
        
        do {
            title = R.string.localizable.analyzedResult()
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
            let handler = UIAction { [unowned self] _ in refreshDataAndPopulateTableView() }
            refreshControl.addAction(handler, for: .primaryActionTriggered)
            
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currency in
                let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
                
                guard let data = analyzedDataDictionary[currency] else { return nil }
                
                let deviationString = NumberFormatter.localizedString(from: NSNumber(value: data.deviation), number: .decimal)
                let meanString = NumberFormatter.localizedString(from: NSNumber(value: data.mean), number: .decimal)
                let latestString = NumberFormatter.localizedString(from: NSNumber(value: data.latest), number: .decimal)
                
                cell.textLabel?.text = [currency.code, currency.localizedString, deviationString].joined(separator: ", ")
                cell.textLabel?.adjustsFontForContentSizeCategory = true
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.textColor = data.deviation < 0 ? .systemGreen : .systemRed
                
                cell.detailTextLabel?.text = R.string.localizable.currencyCellDetail(meanString, latestString)
                cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
                cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
                
                return cell
            }
            dataSource.defaultRowAnimation = .fade
        }
        
        refreshDataAndPopulateTableView()
    }
    
    /// 更新資料
    private func refreshDataAndPopulateTableView() {
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
                
                do { // update table view
                    analyzedDataDictionary = RateListSetAnalyst
                        .analyze(latestRateList: latestRateList,
                                 historicalRateListSet: historicalRateListSet,
                                 baseCurrency: baseCurrency)
                    populateTableView()
                }
                
            case .failure(let error):
                analyzedDataDictionary = [:]
                populateTableView()
                
                showErrorAlert(error: error)
            }
            
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    @IBSegueAction func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        SettingTableViewController(coder: coder,
                                   numberOfDay: numberOfDay,
                                   baseCurrency: baseCurrency) { [unowned self] editedNumberOfDay, editedBaseCurrency in
            do { // base currency
                baseCurrency = editedBaseCurrency
                UserDefaults.standard.set(baseCurrency.rawValue, forKey: "baseCurrency")
            }
            
            do { // number Of Day
                numberOfDay = editedNumberOfDay
                UserDefaults.standard.set(numberOfDay, forKey: "numberOfDay")
            }
            
            refreshDataAndPopulateTableView()
        }
    }
    
    
    /// 更新 table view，純粹把資料填入 table view，不動資料。
    private func populateTableView() {
        
        var sortedTuple = analyzedDataDictionary
            .sorted { $0.value.deviation > $1.value.deviation }
         
        if !searchText.isEmpty { // filtering if needed
            sortedTuple = sortedTuple
                .filter { (currency,_) in
                    [currency.code, currency.localizedString].contains { text in text.lowercased().contains(searchText.lowercased()) }
                }
        }
        
        let sortedCurrencies = sortedTuple.map { $0.key }
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(sortedCurrencies)
        
        dataSource.apply(snapshot)
    }
    
    private func showErrorAlert(error: Error) {
#warning("這出乎我的意料，要向下轉型才讀得到正確的 localizedDescription，要查一下資料。")
        
        let alertController: UIAlertController
        
        do { // alert controller
            let message: String
            
            if let errorMessage = error as? ResponseDataModel.ServerError {
                message = errorMessage.localizedDescription
            } else {
                message = error.localizedDescription
            }
            
            let alertTitle = R.string.localizable.alertTitle()
            alertController = UIAlertController(title: alertTitle,
                                                message: message,
                                                preferredStyle: .alert)
        }
        
        do { // alert action
            let alertActionTitle = R.string.localizable.alertActionTitle()
            let alertAction = UIAlertAction(title: alertActionTitle, style: .cancel) { _ in
                alertController.dismiss(animated: true)
            }
            alertController.addAction(alertAction)
        }
        
        present(alertController, animated: true)
    }
}
    
// MARK: - Search Bar Delegate
extension ResultTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        populateTableView()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText = ""
        populateTableView()
    }
}

// MARK: - name space
private extension ResultTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Currency>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Currency>
}
