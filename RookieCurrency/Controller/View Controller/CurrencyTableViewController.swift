//
//  CurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class CurrencyTableViewController: BaseCurrencyTableViewController {
    
    private var sortingMethod: SortingMethod
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String
    
    private let viewModel: CurrencyTableViewModel
    
    init?(coder: NSCoder, viewModel: CurrencyTableViewModel) {
        
        self.viewModel = viewModel
        
        sortingMethod = .currencyName
        
        sortingOrder = .ascending
        
        searchText = ""
        
        super.init(coder: coder)
        
        title = viewModel.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetcher.fetch(Endpoint.SupportedSymbols()) { [unowned self] result in
            DispatchQueue.main.async { [unowned self] in
                switch result {
                case .success(let supportedSymbols):
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                    #warning("結束下拉更新")
                    populateTableView()
                case .failure(let failure):
                    self.presentErrorAlert(error: failure)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.tableView(tableView, didSelectRowAt: indexPath, with: dataSource)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        viewModel.tableView(tableView, willSelectRowAt: indexPath, with: dataSource)
    }
    
    func search(text searchText: String) {
        self.searchText = searchText
        populateTableView()
    }
    
    override func getSortingMethod() -> SortingMethod {
        sortingMethod
    }
    
    override func populateTableView() {
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
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        
        populateTableView()
        
        super.set(sortingMethod: sortingMethod, sortingOrder: sortingOrder)
    }
    
    override func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
        viewModel.decorate(cell: cell, for: currencyCode)
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
