//
//  BaseCurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/18.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

/// 這裡的 base 是 base class 的意思，不是基準貨幣
class BaseCurrencyTableViewController: UITableViewController {
    
    // MARK: - property
    @IBOutlet weak var sortBarButtonItem: UIBarButtonItem!
    
    let fetcher: Fetcher
    
    let strategy: CurrencyTableStrategy
    
    var dataSource: DataSource!
    
    var currencyCodeDescriptionDictionary: [String: String]
    
    // MARK: - methods
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        fetcher = Fetcher.shared
        
        self.strategy = strategy
        
        currencyCodeDescriptionDictionary = [:]
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        title = strategy.title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelection = strategy.allowsMultipleSelection
        
        // table view data source and delegate
        do {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let identifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
                
                cell.automaticallyUpdatesContentConfiguration = true
                cell.configurationUpdateHandler = { [unowned self] cell, state in
                    var contentConfiguration = cell.defaultContentConfiguration()
                    
                    // content
                    do {
                        let localizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)
                        let serverCurrencyDescription = currencyCodeDescriptionDictionary[currencyCode]
                        
                        switch getSortingMethod() {
                        case .currencyName, .currencyNameZhuyin:
                            contentConfiguration.text = localizedCurrencyDescription ?? serverCurrencyDescription
                            contentConfiguration.secondaryText = currencyCode
                        case .currencyCode:
                            contentConfiguration.text = currencyCode
                            contentConfiguration.secondaryText = localizedCurrencyDescription ?? serverCurrencyDescription
                        }
                    }
                    
                    // font
                    do {
                        contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
                        contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
                        
                        contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
                        contentConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
                    }
                    
                    // other
                    do {
                        contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                        contentConfiguration.textToSecondaryTextVerticalPadding = 4
                    }
                    
                    cell.contentConfiguration = contentConfiguration
                    cell.accessoryType = state.isSelected ? .checkmark : .none
                }
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
        }
        
        // sort bar button item
        do {
            
            let currencyNameMenu: UIMenu
            
            let ascendingAction: UIAction
            
            do {
                ascendingAction = UIAction(title: SortingOrder.ascending.localizedName,
                                           image: UIImage(systemName: "arrow.up.right"),
                                           state: .on,
                                           handler: { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .ascending) })
                
                let descendingAction = UIAction(title: SortingOrder.descending.localizedName,
                                                image: UIImage(systemName: "arrow.down.right"),
                                                handler: { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .descending) })
                
                currencyNameMenu = UIMenu(title: SortingMethod.currencyName.localizedName,
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
                
                currencyCodeMenu = UIMenu(title: SortingMethod.currencyCode.localizedName,
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
                
                let currencyZhuyinMenu = UIMenu(title: SortingMethod.currencyNameZhuyin.localizedName,
                                                children: [ascendingAction, descendingAction])
                
                children.append(currencyZhuyinMenu)
            }
            
            let sortMenu = UIMenu(title: R.string.localizable.sortedBy(),
                                  image: UIImage(systemName: "arrow.up.arrow.down"),
                                  options: .singleSelection,
                                  children: children)
            
            sortBarButtonItem.menu = UIMenu(title: "",
                                            options: .singleSelection,
                                            children: [sortMenu])
            
            // set up the initial state
            do {
                ascendingAction.state = .on
                
                // The value of properties `sortingMethod` and `sortingOrder` could be changed between the call of `init` and `viewDidLoad`,
                // so we need to reset them in order to be consistent with the ascendingAction.state
                sortBarButtonItem.menu?.children.first?.subtitle = R.string.localizable.sortingWay(getSortingMethod().localizedName, getSortingOrder().localizedName)
                #warning("確定一下 subtitle 能不能跟後續點擊一樣改變")
                
//                set(sortingMethod: .currencyName, sortingOrder: .ascending)
                #warning("出事啦 這樣給初始值 imperative target 會 crash")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Hook methods
    func getSortingMethod() -> SortingMethod {
        fatalError("getSortingMethod() has not been implemented")
    }
    
    func getSortingOrder() -> SortingOrder {
        fatalError("getSortingOrder() has not been implemented")
    }
    
    func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        fatalError("set(sortingMethod:sortingOrder:) has not been implemented")
    }
}

// MARK: - table view delegate relative
extension BaseCurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
            assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
            return
        }
        
        strategy.select(currencyCode: selectedCurrencyCode)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard let deselectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
            assertionFailure("###, \(self), \(#function), 取消選取的 item 不在 data source 中，這不可能發生。")
            return
        }
        strategy.deselect(currencyCode: deselectedCurrencyCode)
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
            case .currencyName: return R.string.localizable.currencyName()
            case .currencyCode: return R.string.localizable.currencyCode()
            case .currencyNameZhuyin: return R.string.localizable.currencyZhuyin()
            }
        }
    }
    
    enum SortingOrder {
        case ascending
        case descending
        
        var localizedName: String {
            switch self {
            case .ascending: return R.string.localizable.ascending()
            case .descending: return R.string.localizable.decreasing()
            }
        }
    }
}

// MARK: - Error Alert Presenter
extension BaseCurrencyTableViewController: ErrorAlertPresenter {}

// MARK: - strategy
protocol CurrencyTableStrategy {
    
    var title: String { get }
    
    var selectedCurrencies: Set<ResponseDataModel.CurrencyCode> { get }
    
    var allowsMultipleSelection: Bool { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
}
