//
//  BaseResultTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/20.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class BaseResultTableViewController: UITableViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var updatingStatusItem: UIBarButtonItem!
    
    @IBOutlet weak var sortItem: UIBarButtonItem!
    
    /// 分析過的匯率資料
    var analyzedDataDictionary: [ResponseDataModel.CurrencyCode: (latest: Double, mean: Double, deviation: Double)]
    
    private var dataSource: DataSource!
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        analyzedDataDictionary = [:]
        
        super.init(coder: coder)
        
        // search controller
        do {
            let searchController = UISearchController()
            searchController.searchBar.delegate = self
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        // 在 app 內顯示 app icon，以便看出是哪個 target
        do {
            let imageView = UIImageView(image: UIImage(named: "AppIcon"))
            let rightBarButton = UIBarButtonItem(customView: imageView)
            rightBarButton.isEnabled = false
            navigationItem.setRightBarButton(rightBarButton, animated: false)
        }
        
        title = R.string.localizable.analyzedResult()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // refresh control
        do {
            refreshControl = UIRefreshControl()
            let handler = UIAction { [unowned self] _ in refreshControlTriggered() }
            refreshControl?.addAction(handler, for: .primaryActionTriggered)
        }
        
        // updatingStatusItem
        do {
            updatingStatusItem.isEnabled = false
            updatingStatusItem.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .disabled)
        }
        
        // table view data source
        do {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
                
                guard let data = analyzedDataDictionary[currencyCode] else { return cell }
                
                let deviationString = NumberFormatter.localizedString(from: NSNumber(value: data.deviation), number: .decimal)
                let meanString = NumberFormatter.localizedString(from: NSNumber(value: data.mean), number: .decimal)
                let latestString = NumberFormatter.localizedString(from: NSNumber(value: data.latest), number: .decimal)
                
                cell.textLabel?.text = [currencyCode,
                                        Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode),
                                        deviationString]
                    .compactMap { $0 }
                    .joined(separator: ", ")
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
    }
    
    func setOrder(_ order: Order) {
        fatalError("select(order:) has not been implemented")
    }
    
    func refreshControlTriggered() {
        fatalError("refreshControlTriggered()")
    }
    
    @IBSegueAction func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        fatalError("showSetting(_:) has not been implemented")
    }
    
    /// 更新 table view，純粹把資料填入 table view，不動資料。
    final func populateTableView(analyzedDataDictionary: [ResponseDataModel.CurrencyCode: (latest: Double, mean: Double, deviation: Double)],
                                 order: Order,
                                 searchText: String) {
        var sortedTuple = analyzedDataDictionary
            .sorted { lhs, rhs in
                switch order {
                case .increasing:
                    return lhs.value.deviation < rhs.value.deviation
                case .decreasing:
                    return lhs.value.deviation > rhs.value.deviation
                }
            }
        
        if !searchText.isEmpty { // filtering if needed
            sortedTuple = sortedTuple
                .filter { (currencyCode,_) in
                    [currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)]
                        .compactMap { $0 }
                        .contains { text in text.localizedStandardContains(searchText) }
                }
        }
        
        let sortedCurrencies = sortedTuple.map { $0.key }
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(sortedCurrencies)
        snapshot.reloadSections([.main])
        
        dataSource.apply(snapshot)
    }
    
    final func showErrorAlert(error: Error) {

        let alertController: UIAlertController
        
        // alert controller
        do {
            let alertTitle = R.string.localizable.alertTitle()
            alertController = UIAlertController(title: alertTitle,
                                                message: error.localizedDescription,
                                                preferredStyle: .alert)
        }
        
        // alert action
        do {
            let alertActionTitle = R.string.localizable.alertActionTitle()
            let alertAction = UIAlertAction(title: alertActionTitle, style: .cancel)
            alertController.addAction(alertAction)
        }
        
        present(alertController, animated: true)
    }
}

// MARK: - Search Bar Delegate
extension BaseResultTableViewController: UISearchBarDelegate {}

// MARK: - name space
extension BaseResultTableViewController {
    /// 資料的排序方式。
    /// 因為要儲存在 UserDefaults，所以 access control 不能是 private。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedName: String {
            switch self {
            case .increasing: return R.string.localizable.increasing()
            case .decreasing: return R.string.localizable.decreasing()
            }
        }
        
    }
}

// MARK: - name space
private extension BaseResultTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
}
