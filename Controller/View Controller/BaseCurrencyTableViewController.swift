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
    
    #warning("改完可以刪掉 fetcher")
    let fetcher: Fetcher
    
    let strategy: CurrencyTableStrategy
    
    var dataSource: DataSource!
    
    var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]?
    
    // MARK: - life cycle
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        fetcher = Fetcher.shared
        
        self.strategy = strategy
        
        currencyCodeDescriptionDictionary = nil
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        title = strategy.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                        guard let currencyCodeDescriptionDictionary else {
                            assertionFailure("###, \(self), \(#function), 這段是 dead code，因為會進到這裡的 currency code 都是從 currencyCodeDescriptionDictionary 中 filter 剩下的。")
                            return
                        }
                        let serverCurrencyDescription = currencyCodeDescriptionDictionary[currencyCode]
                        
                        let currencyDescription = localizedCurrencyDescription ?? serverCurrencyDescription
                        
                        switch getSortingMethod() {
                        case .currencyName, .currencyNameZhuyin:
                            contentConfiguration.text = currencyDescription
                            contentConfiguration.secondaryText = currencyCode
                        case .currencyCode:
                            contentConfiguration.text = currencyCode
                            contentConfiguration.secondaryText = currencyDescription
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
                // action state 的初始值只能在這裡設定，但不能用程式模擬使用者點擊 action，為了確保初始值一致，必須在這裡設定一次 sorting method 跟 sorting order
                set(sortingMethod: .currencyName, sortingOrder: .ascending)
            }
        }
        
        // table view refresh controller
        do {
            tableView.refreshControl = UIRefreshControl()
            
            let action = UIAction { [unowned self] _ in triggerRefreshControl() }
            tableView.refreshControl?.addAction(action, for: .primaryActionTriggered)
            
            tableView.refreshControl?.beginRefreshing()
            tableView.refreshControl?.sendActions(for: .primaryActionTriggered)
        }
    }
    
    // MARK: - method
    final func convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String],
                                                sortingMethod: SortingMethod,
                                                sortingOrder: SortingOrder,
                                                searchText: String,
                                                isFirstTimePopulate: Bool) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        let currencyCodes = currencyCodeDescriptionDictionary.keys
        
        let sortedCurrencyCodes = currencyCodes.sorted { lhs, rhs in
            
            switch sortingMethod {
            case .currencyName, .currencyNameZhuyin:
                let lhsString: String
                do {
                    let lhsLocalizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: lhs)
                    let lhsServerCurrencyDescription = currencyCodeDescriptionDictionary[lhs]
                    lhsString = lhsLocalizedCurrencyDescription ?? lhsServerCurrencyDescription ?? lhs
                }
                
                let rhsString: String
                do {
                    let rhsLocalizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: rhs)
                    let rhsServerCurrencyDescription = currencyCodeDescriptionDictionary[rhs]
                    rhsString = rhsLocalizedCurrencyDescription ?? rhsServerCurrencyDescription ?? rhs
                }
                
                if sortingMethod == .currencyName {
                    switch sortingOrder {
                    case .ascending:
                        return lhsString.localizedStandardCompare(rhsString) == .orderedAscending
                    case .descending:
                        return lhsString.localizedStandardCompare(rhsString) == .orderedDescending
                    }
                } else if sortingMethod == .currencyNameZhuyin {
                    let zhuyinLocale = Locale(identifier: "zh@collation=zhuyin")
                    switch sortingOrder {
                    case .ascending:
                        return lhsString.compare(rhsString, locale: zhuyinLocale) == .orderedAscending
                    case .descending:
                        return lhsString.compare(rhsString, locale: zhuyinLocale) == .orderedDescending
                    }
                } else {
                    assertionFailure("###, \(self), \(#function), 這段是 dead code")
                    return false
                }
                
            case .currencyCode:
                switch sortingOrder {
                case .ascending:
                    return lhs.localizedStandardCompare(rhs) == .orderedAscending
                case .descending:
                    return lhs.localizedStandardCompare(rhs) == .orderedDescending
                }
            }
        }
        
        var filteredCurrencyCodes = sortedCurrencyCodes
        
        if !searchText.isEmpty {
            filteredCurrencyCodes = sortedCurrencyCodes
                .filter { currencyCode in
                    [currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)]
                        .compactMap { $0 }
                        .contains { text in text.localizedStandardContains(searchText) }
                }
        }
        
        snapshot.appendItems(filteredCurrencyCodes)
        snapshot.reloadSections([.main])
        
        DispatchQueue.main.async { [weak self] in
            
            self?.dataSource.apply(snapshot) { [weak self] in
                guard let self else { return }
                
                let selectedIndexPath = strategy.selectedCurrencies
                    .compactMap { [weak self] selectedCurrencyCode in self?.dataSource.indexPath(for: selectedCurrencyCode) }
                
                selectedIndexPath
                    .forEach { [weak self] indexPath in self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none) }
                
                // scroll to first selected index path when first time receiving data
                if isFirstTimePopulate {
                    
                    if let firstSelectedIndexPath = selectedIndexPath.min()  {
                        tableView.scrollToRow(at: firstSelectedIndexPath, at: .top, animated: true)
                    }
                    else {
                        presentAlert(message: "### 服務商已不支援先前所選的貨幣，請重新選取。")
                    }
                }
            }
        }
    }

    // MARK: - Hook methods
    func getSortingMethod() -> SortingMethod {
        fatalError("getSortingMethod() has not been implemented")
    }
    
    func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        fatalError("set(sortingMethod:sortingOrder:) has not been implemented")
    }
    
    func triggerRefreshControl() {
        fatalError("triggerRefreshControl() has not been implemented")
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
            case .descending: return R.string.localizable.descending()
            }
        }
    }
}

// MARK: - private name space
extension BaseCurrencyTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
}

// MARK: - Alert Presenter
extension BaseCurrencyTableViewController: AlertPresenter {}

// MARK: - strategy
protocol CurrencyTableStrategy {
    
    var title: String { get }
    
    var selectedCurrencies: Set<ResponseDataModel.CurrencyCode> { get }
    
    var allowsMultipleSelection: Bool { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
}
