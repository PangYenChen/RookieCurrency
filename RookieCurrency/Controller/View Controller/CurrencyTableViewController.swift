//
//  CurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class CurrencyTableViewController: BaseCurrencyTableViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private var sortBarButtonItem: UIBarButtonItem!
    
    // MARK: - private properties
    private var sortingMethod: SortingMethod
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String
    
    private var currencyCodeDescriptionDictionary: [String: String]
    
    private var dataSource: DataSource!
    
    private let fetcher: Fetcher
    
    private let viewModel: CurrencyTableViewModel
    
    init?(coder: NSCoder, viewModel: CurrencyTableViewModel) {
        
        self.viewModel = viewModel
        
        sortingMethod = .currencyName
        
        sortingOrder = .ascending
        
        searchText = ""
        
        currencyCodeDescriptionDictionary = [:]
        
        fetcher = Fetcher.shared
        
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
        
        // table view data source and delegate
        do {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let identifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
                
                do {
                    let localizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)
                    let serverCurrencyDescription = currencyCodeDescriptionDictionary[currencyCode]
                    
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
                
                viewModel.decorate(cell: cell, for: currencyCode)
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
            
            tableView.delegate = self
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
            
            // set up the initial state
            ascendingAction.state = .on
            
            // The properties `sortingMethod` and `sortingOrder` could be changed between the call of `init` and `viewDidLoad`,
            // so we need to reset them to the initial values as needed.
            set(sortingMethod: .currencyName, sortingOrder: .ascending)
        }
        
        
        // table view refresh controller
        do {
            tableView.refreshControl = UIRefreshControl()
            
            let action = UIAction { [unowned self] _ in refreshControlTriggered() }
            tableView.refreshControl?.addAction(action, for: .primaryActionTriggered)
            
            tableView.refreshControl?.beginRefreshing()
            tableView.refreshControl?.sendActions(for: .primaryActionTriggered)
        }
    }
}

// MARK: - table view delegate relative
extension CurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.tableView(tableView, didSelectRowAt: indexPath, with: dataSource)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        viewModel.tableView(tableView, willSelectRowAt: indexPath, with: dataSource)
    }
}

// MARK: - search bar delegate relative
extension CurrencyTableViewController {
    func search(text searchText: String) {
        self.searchText = searchText
        populateTableView()
    }
}

// MARK: - private method
private extension CurrencyTableViewController {
    func refreshControlTriggered() {
        fetcher.fetch(Endpoint.SupportedSymbols()) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let supportedSymbols):
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                    populateTableView()
                case .failure(let failure):
                    presentErrorAlert(error: failure)
                }
                
                tableView.refreshControl?.endRefreshing()
            }
        }
    }
        
    func populateTableView() {
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
        
        dataSource.apply(snapshot)
    }
    
    func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = sortingMethod.localizedName + sortingOrder.localizedName
        
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        
        populateTableView()
    }
}

// MARK: - view model
extension CurrencyTableViewController {

    class BaseCurrencySelectionViewModel: CurrencyTableViewModel {
        
        let title: String
        
        private var baseCurrencyCode: String
        
        private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
        
        init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
            title = R.string.localizable.baseCurrency()
            self.baseCurrencyCode = baseCurrencyCode
            self.completionHandler = completionHandler
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            cell.accessoryType = currencyCode == baseCurrencyCode ? .checkmark : .none
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, with dataSource: DataSource) {
            
            var identifiersNeedToBeReloaded: [ResponseDataModel.CurrencyCode] = []
            
            guard let newSelectedBaseCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
                assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
                return
            }
            
            identifiersNeedToBeReloaded.append(newSelectedBaseCurrencyCode)
            
            if let oldSelectedBaseCurrencyIndexPath = dataSource.indexPath(for: baseCurrencyCode),
               tableView.indexPathsForVisibleRows?.contains(oldSelectedBaseCurrencyIndexPath) == true {
                identifiersNeedToBeReloaded.append(baseCurrencyCode)
            }
            
            baseCurrencyCode = newSelectedBaseCurrencyCode
            
            var snapshot = dataSource.snapshot()
            snapshot.reloadItems(identifiersNeedToBeReloaded)
            dataSource.apply(snapshot)
            
            completionHandler(newSelectedBaseCurrencyCode)
        }
        
        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath, with dataSource: DataSource) -> IndexPath? {
            dataSource.indexPath(for: baseCurrencyCode) == indexPath ? nil : indexPath
        }
    }
    
    class CurrencyOfInterestSelectionViewModel: CurrencyTableViewModel {
        
        let title: String
        
        private var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
        
        private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
        
        init(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
             completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
            title = R.string.localizable.currencyOfInterest()
            self.currencyOfInterest = currencyOfInterest
            self.completionHandler = completionHandler
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            cell.accessoryType = currencyOfInterest.contains(currencyCode) ? .checkmark : .none
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, with dataSource: DataSource) {
            
            guard let selectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
                assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
                return
            }
            
            if currencyOfInterest.contains(selectedCurrencyCode) {
                currencyOfInterest.remove(selectedCurrencyCode)
            } else {
                currencyOfInterest.insert(selectedCurrencyCode)
            }
            
            var snapshot = dataSource.snapshot()
            snapshot.reloadItems([selectedCurrencyCode])
            dataSource.apply(snapshot)
        }
        
        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath, with dataSource: DataSource) -> IndexPath? {
            indexPath
        }
    }
}
