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
    
    private var sortingMethod: SortingMethod
    
    private var sortingOrder: SortingOrder
    
    private let fetcher: Fetcher
    
    let viewModel: CurrencyTableViewModel
    
    // MARK: - methods
    init?(coder: NSCoder, viewModel: CurrencyTableViewModel) {
        
        currencyCodeDescriptionDictionary = [:]
        
        currencyCodes = []
        
        self.viewModel = viewModel
        
        sortingMethod = .currencyName
        
        sortingOrder = .ascending
        
        self.fetcher = Fetcher.shared
        
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
        
        // table view data source
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
            
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(currencyCodes)
            
            dataSource.apply(snapshot)
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
                let zhuyinLocale = Locale(identifier: "zh@collation=zhuyin")
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
            set(sortingMethod: sortingMethod, sortingOrder: sortingOrder)
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
                    #warning("dead code 要處理一下")
                    assertionFailure("ajhwe;fijaw;efoij")
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
    
    private func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        sortBarButtonItem.menu?.children.first?.subtitle = sortingMethod.localizedName + sortingOrder.localizedName
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

// MARK: - Table View Delegate
extension BaseCurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tappedCurrencyCode = currencyCodes[indexPath.row]
        viewModel.didTap(currencyCode: tappedCurrencyCode)
    }
}


// MARK: - Currency Table View Model
protocol CurrencyTableViewModel {
    var title: String { get }
    
    func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode)
    
    func didTap(currencyCode: ResponseDataModel.CurrencyCode)
}
