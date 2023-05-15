//
//  BaseCurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/18.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

/// 這裡的 base 是 base class 的意思，不是基準幣別
class BaseCurrencyTableViewController: UITableViewController {
    
    // MARK: - private properties
    @IBOutlet weak var sortBarButtonItem: UIBarButtonItem!
    
    private(set) var dataSource: DataSource!
    
    var currencyCodeDescriptionDictionary: [String: String]
    
    let fetcher: Fetcher
    
    // MARK: - methods
    required init?(coder: NSCoder) {
        
        currencyCodeDescriptionDictionary = [:]
        
        fetcher = Fetcher.shared
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // table view data source and delegate
        do {
            tableView.refreshControl?.beginRefreshing()
            
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let identifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
                
                do {
                    let localizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)
                    let serverCurrencyDescription = currencyCodeDescriptionDictionary[currencyCode]
                    
                    let sortingMethod = getSortingMethod()
                    
                    switch sortingMethod {
                    case .currencyName, .currencyNameZhuyin:
                        cell.textLabel?.text = localizedCurrencyDescription ?? serverCurrencyDescription
                        cell.detailTextLabel?.text = currencyCode
                    case .currencyCode:
                        cell.textLabel?.text = currencyCode
                        cell.detailTextLabel?.text = localizedCurrencyDescription ?? serverCurrencyDescription
                    }
                }
                
                
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.adjustsFontForContentSizeCategory = true
                
                decorate(cell: cell, for: currencyCode)
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
            
            tableView.delegate = self
        }
        
        
        // sort bar button item
        do {
            
            let currencyNameMenu: UIMenu
            do {
                let ascendingAction = UIAction(title: SortingOrder.ascending.localizedName,
                                               image: UIImage(systemName: "arrow.up.right"),
                                               state: .on,
                                               handler: { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .ascending) })
#warning("初始化的邏輯散落各地")
                
                let descendingAction = UIAction(title: SortingOrder.descending.localizedName,
                                                image: UIImage(systemName: "arrow.down.right"),
                                                handler: { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .descending) })
                
                currencyNameMenu = UIMenu(title: "＃＃幣別名稱",
                                          children: [ascendingAction, descendingAction])
            }
            
            let currencyCodeMenu: UIMenu
            do {
                let ascendingAction = UIAction(title: SortingOrder.ascending.localizedName,
                                               image: UIImage(systemName: "arrow.up.right"),
                                               handler: { [unowned self] _ in set(sortingMethod: .currencyCode, sortingOrder: .ascending) })
                
                let descendingAction = UIAction(title: SortingOrder.descending.localizedName,
                                                image: UIImage(systemName: "arrow.down.right"),
                                                handler: { [unowned self] _ in set(sortingMethod: .currencyCode, sortingOrder: .descending) })
                
                currencyCodeMenu = UIMenu(title: "＃＃幣別代碼",
                                          children: [ascendingAction, descendingAction])
            }
            
            var children = [currencyNameMenu, currencyCodeMenu]
            
            // 注音
            if Bundle.main.preferredLocalizations.first == "zh-Hant" {
                let ascendingAction = UIAction(title: SortingOrder.ascending.localizedName,
                                               image: UIImage(systemName: "arrow.up.right"),
                                               handler: { [unowned self] _ in set(sortingMethod: .currencyNameZhuyin, sortingOrder: .ascending) })
                
                let descendingAction = UIAction(title: SortingOrder.descending.localizedName,
                                                image: UIImage(systemName: "arrow.down.right"),
                                                handler: { [unowned self] _ in set(sortingMethod: .currencyNameZhuyin, sortingOrder: .descending) })
                
                let currencyZhuyinMenu = UIMenu(title: "＃＃幣別注音",
                                                children: [ascendingAction, descendingAction])
                
                children.append(currencyZhuyinMenu)
            }
            
            let sortMenu = UIMenu(title: R.string.localizable.sortedBy(),
                                  subtitle: "## 目前使用貨幣名稱的升冪排序",
                                  image: UIImage(systemName: "arrow.up.arrow.down"),
                                  options: .singleSelection,
                                  children: children)
            
            sortBarButtonItem.menu = UIMenu(title: "",
                                            options: .singleSelection,
                                            children: [sortMenu])
            
            #warning("這個不舒服，可以想想怎麼 init sorting order，初始化的邏輯散落各地")
//            set(sortingMethod: sortingMethod, sortingOrder: sortingOrder)
        }
    }
    
    func populateTableView() {
        fatalError("populateTableView() has not been implemented.")
    }
    
    func getSortingMethod() -> SortingMethod {
        fatalError("getSortingMethod() has not been implemented.")
    }
    
    func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
        fatalError("decorate(cell:for:) has not been implemented.")
    }
    
    func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = sortingMethod.localizedName + sortingOrder.localizedName
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencyTableViewController: UISearchBarDelegate {}

// MARK: - name space
extension BaseCurrencyTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
    enum SortingMethod {
        case currencyName
        case currencyCode
        case currencyNameZhuyin
        
        var localizedName: String {
            switch self {
            case .currencyName: return "## 貨幣名稱"
            case .currencyCode: return "## 貨幣代碼"
            case .currencyNameZhuyin: return "## 貨幣注音"
            }
        }
    }
    
    enum SortingOrder {
        case ascending
        case descending
        
        var localizedName: String {
            switch self {
            case .ascending: return "## 升冪排列"
            case .descending: return "## 降冪排列"
            }
        }
    }
}

// MARK: - Error Alert Presenter
extension BaseCurrencyTableViewController: ErrorAlertPresenter {}

// MARK: - Currency Table View Model
protocol CurrencyTableViewModel {
    var title: String { get }
    
    func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode)
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath,
                   with dataSource: BaseCurrencyTableViewController.DataSource)
    
    func tableView(_ tableView: UITableView,
                   willSelectRowAt indexPath: IndexPath,
                   with dataSource: BaseCurrencyTableViewController.DataSource) -> IndexPath?
}
