//
//  CurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class CurrencyTableViewController: BaseCurrencyTableViewController {
    
    // MARK: - private properties
    private var sortingMethod: SortingMethod
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String
    
    private var isReceivingFirstData: Bool
    
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        sortingMethod = .currencyName
        
        sortingOrder = .ascending
        
        searchText = ""
        
        isReceivingFirstData = true
        
        super.init(coder: coder, strategy: strategy)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // table view refresh controller
        do {
            tableView.refreshControl = UIRefreshControl()
            
            let action = UIAction { [unowned self] _ in refreshControlTriggered() }
            tableView.refreshControl?.addAction(action, for: .primaryActionTriggered)
            
            tableView.refreshControl?.beginRefreshing()
            tableView.refreshControl?.sendActions(for: .primaryActionTriggered)
        }
    }
    
    // MARK: - Hook methods
    override func getSortingOrder() -> BaseCurrencyTableViewController.SortingOrder {
        sortingOrder
    }
    
    override func getSortingMethod() -> BaseCurrencyTableViewController.SortingMethod {
        sortingMethod
    }
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = R.string.localizable.sortingWay(sortingMethod.localizedName, sortingOrder.localizedName)
        
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        
        convertDataThenPopulateTableView()
    }
}

// MARK: - table view delegate relative
extension CurrencyTableViewController {
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

// MARK: - search bar delegate
extension CurrencyTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        convertDataThenPopulateTableView()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText = ""
        convertDataThenPopulateTableView()
    }
}

// MARK: - private method
private extension CurrencyTableViewController {
    func refreshControlTriggered() {
        fetcher.fetch(Endpoints.SupportedSymbols()) { [weak self] result in
            guard let self else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
            
            switch result {
            case .success(let supportedSymbols):
                currencyCodeDescriptionDictionary = supportedSymbols.symbols
                convertDataThenPopulateTableView()
            case .failure(let failure):
                DispatchQueue.main.async { [weak self] in
                    self?.presentErrorAlert(error: failure)
                }
            }
        }
    }
    
    func convertDataThenPopulateTableView() {
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
        
        DispatchQueue.main.async { [weak self] in
            
            self?.dataSource.apply(snapshot) { [weak self] in
                guard let self else { return }
                
                let selectedIndexPath = strategy.selectedCurrencies
                    .compactMap { [weak self] selectedCurrencyCode in self?.dataSource.indexPath(for: selectedCurrencyCode) }
                
                selectedIndexPath
                    .forEach { [weak self] indexPath in self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none) }
                
                // scroll to first selected index path when first time receiving data
                if self.isReceivingFirstData {
                    guard let firstSelectedIndexPath = selectedIndexPath.min() else  {
                        assertionFailure("###, \(self), \(#function), 資料發生錯誤，外面傳進來的資料不能是空的")
                        return
                    }
                    tableView.scrollToRow(at: firstSelectedIndexPath, at: .top, animated: true)
                    self.isReceivingFirstData = false
                }
            }
        }
        
    }
}

// MARK: - strategy
extension CurrencyTableViewController {
    
    class BaseCurrencySelectionStrategy: CurrencyTableStrategy {
        
        let title: String
        
        private var baseCurrencyCode: String
        
        var selectedCurrencies: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode] }
        
        let allowsMultipleSelection: Bool
        
        private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
        
        init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
            title = R.string.localizable.baseCurrency()
            self.baseCurrencyCode = baseCurrencyCode
            allowsMultipleSelection = false
            self.completionHandler = completionHandler
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            
            completionHandler(selectedCurrencyCode)
            baseCurrencyCode = selectedCurrencyCode
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            // allowsMultipleSelection = false，會呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
        }
    }
    
    class CurrencyOfInterestSelectionStrategy: CurrencyTableStrategy {
        
        let title: String
        
        private var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
        
        var selectedCurrencies: Set<ResponseDataModel.CurrencyCode> { currencyOfInterest }
        
        let allowsMultipleSelection: Bool
        
        private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
        
        init(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
             completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
            title = R.string.localizable.currencyOfInterest()
            self.currencyOfInterest = currencyOfInterest
            allowsMultipleSelection = true
            self.completionHandler = completionHandler
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyOfInterest.insert(selectedCurrencyCode)
            completionHandler(currencyOfInterest)
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyOfInterest.remove(deselectedCurrencyCode)
            completionHandler(currencyOfInterest)
        }
    }
}
