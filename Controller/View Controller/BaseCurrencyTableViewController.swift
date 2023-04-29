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
    
    let viewModel: SelectionBaseCurrencyViewModel
    
    // MARK: - methods
    init?(coder: NSCoder, viewModel: SelectionBaseCurrencyViewModel) {
        
        
        self.viewModel = viewModel
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
        }
        
        title = viewModel.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.configureDataSourceAndDeletate(tableView: tableView)
        
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
    
    private func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = sortingMethod.localizedName + sortingOrder.localizedName
        viewModel.set(sortingMethod: sortingMethod, sortingOrder: sortingOrder)
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencyTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(text: searchText)
    }
}

// MARK: - private name space
extension BaseCurrencyTableViewController {
    
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


