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
    
    private var currencyCodeDescriptionDictionary: [String: String]
    
    private(set) var currencyCodes: [ResponseDataModel.CurrencyCode]
    
    private var dataSource: DataSource!
    
    var selectionItem: SelectionItem
    
    private var sortingOrder: SortingOrder
    
    private let fetcher: Fetcher
    
    // MARK: - methods
    init?(coder: NSCoder, selectionItem: SelectionItem) {
        
        currencyCodeDescriptionDictionary = [:]
        
        currencyCodes = []
        
        self.selectionItem = selectionItem
        
        sortingOrder = .currencyNameAscending
        
        self.fetcher = Fetcher.shared
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
        }
        
        
        switch selectionItem {
        case .baseCurrency:
            title = R.string.localizable.currency()
        case .currencyOfInterest:
            title = R.string.localizable.currencyOfInterest()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // table view data source
        do {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let identifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
                
                do {
                    let localizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)
                    let serverCurrencyDescription = currencyCodeDescriptionDictionary[currencyCode]
                    
                    switch sortingOrder {
                    case .currencyNameAscending, .currencyNameDescending:
                        cell.textLabel?.text = localizedCurrencyDescription ?? serverCurrencyDescription
                        cell.detailTextLabel?.text = currencyCode
                    case .currencyCodeAscending, .currencyCodeDescending:
                        cell.textLabel?.text = currencyCode
                        cell.detailTextLabel?.text = localizedCurrencyDescription ?? serverCurrencyDescription
                    }
                }
                
                
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.adjustsFontForContentSizeCategory = true
                
                switch selectionItem {
                case .baseCurrency(let baseCurrency):
                    if currencyCode == baseCurrency {
                        cell.accessoryType = .checkmark
                    } else {
                        cell.accessoryType = .none
                    }
                case .currencyOfInterest(let currencyOfInterest):
                    if currencyOfInterest.contains(currencyCode) {
                        cell.accessoryType = .checkmark
                    } else {
                        cell.accessoryType = .none
                    }
                }
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
            
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(currencyCodes)
            
            dataSource.apply(snapshot)
        }
        
        // sort bar button item
        do {
            
            let currencyNameMenu: UIMenu
            do {
                let ascendingAction = UIAction(title: SortingOrder.currencyNameAscending.localizedName,
                                               image: UIImage(systemName: "arrow.up.right"),
                                               state: .on,
                                               handler: { [unowned self] _ in setSortingOrder(.currencyNameAscending) })
#warning("初始化的邏輯散落各地")
                
                let descendingAction = UIAction(title: SortingOrder.currencyNameDescending.localizedName,
                                                image: UIImage(systemName: "arrow.down.right"),
                                                handler: { [unowned self] _ in setSortingOrder(.currencyNameDescending)})
                
                currencyNameMenu = UIMenu(title: "＃＃幣別名稱",
                                          children: [ascendingAction, descendingAction])
            }
            
            let currencyCodeMenu: UIMenu
            do {
                let ascendingAction = UIAction(title: SortingOrder.currencyCodeAscending.localizedName,
                                               image: UIImage(systemName: "arrow.up.right"),
                                               handler: { [unowned self] _ in setSortingOrder(.currencyCodeAscending) })
                
                let descendingAction = UIAction(title: SortingOrder.currencyCodeDescending.localizedName,
                                                image: UIImage(systemName: "arrow.down.right"),
                                                handler: { [unowned self] _ in setSortingOrder(.currencyNameDescending)})
                
                currencyCodeMenu = UIMenu(title: "＃＃幣別代碼",
                                          children: [ascendingAction, descendingAction])
            }
            
            let sortMenu = UIMenu(title: R.string.localizable.sortedBy(),
                                  subtitle: "## 目前使用貨幣名稱的升冪排序",
                                  image: UIImage(systemName: "arrow.up.arrow.down"),
                                  options: .singleSelection,
                                  children: [currencyNameMenu, currencyCodeMenu])
            
            sortBarButtonItem.menu = UIMenu(title: "",
                                            options: .singleSelection,
                                            children: [sortMenu])
            
            #warning("這個不舒服，可以想想怎麼 init sorting order，初始化的邏輯散落各地")
            setSortingOrder(.currencyNameAscending)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetcher.fetch(Endpoint.SupportedSymbols()) { [unowned self] result in
            DispatchQueue.main.async { [unowned self] in
                switch result {
                case .success(let supportedSymbols):
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                    currencyCodes = supportedSymbols.symbols.keys.map { $0 }
                        .sorted()
                    populateTableView()
                case .failure(let failure):
                    presentErrorAlert(error: failure)
                }
            }
        }
    }
    
    // MARK: - private method
    private func populateTableView(for searchText: String = "") {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        let sortedCurrencyCodes = currencyCodes.sorted { lhs, rhs in
            switch sortingOrder {
                
            case .currencyNameAscending:
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
                
                return lhsString.localizedStandardCompare(rhsString) == .orderedAscending
            case .currencyNameDescending:
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
                
                return lhsString.localizedStandardCompare(rhsString) == .orderedDescending
            case .currencyCodeAscending:
                return lhs.localizedStandardCompare(rhs) == .orderedAscending
            case .currencyCodeDescending:
                return lhs.localizedStandardCompare(rhs) == .orderedDescending
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
    
    private func setSortingOrder(_ sortingOrder: SortingOrder) {
        self.sortingOrder = sortingOrder
        sortBarButtonItem.menu?.children.first?.subtitle = sortingOrder.localizedName
        #warning("之後要帶資訊給 table view")
        populateTableView()
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencyTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        populateTableView(for: searchText)
    }
}

// MARK: - private name space
private extension BaseCurrencyTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
    enum SortingOrder {
        case currencyNameAscending
        case currencyNameDescending
        case currencyCodeAscending
        case currencyCodeDescending
        
        var localizedName: String {
            switch self {
            case .currencyNameAscending: return "## 貨幣名稱 升冪排列"
            case .currencyNameDescending: return "## 貨幣名稱 降冪排列"
            case .currencyCodeAscending: return "## 貨幣代買 升冪排列"
            case .currencyCodeDescending: return "## 貨幣代碼 降冪排列"
            }
        }
    }
}
// MARK: - internal name space
extension BaseCurrencyTableViewController {
    enum SelectionItem {
        case baseCurrency(ResponseDataModel.CurrencyCode)
        case currencyOfInterest(Set<ResponseDataModel.CurrencyCode>)
    }
}

// MARK: - Error Alert Presenter
extension BaseCurrencyTableViewController: ErrorAlertPresenter {}
