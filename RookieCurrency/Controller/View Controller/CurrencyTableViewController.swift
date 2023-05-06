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
    
    private let viewModel: ViewModel
    
    init?(coder: NSCoder, viewModel: ViewModel) {
        
        self.viewModel = viewModel
        
        sortingMethod = .currencyName
        
        sortingOrder = .ascending
        
        searchText = ""
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewModel.title
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
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        
#warning("之後要帶資訊給 table view")
        populateTableView()
        
        super.set(sortingMethod: sortingMethod, sortingOrder: sortingOrder)
    }
    
    override func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
        viewModel.decorate(cell: cell, for: currencyCode)
    }
}


extension BaseCurrencyTableViewController {

    class ViewModel {
        
        let title: String = "### AAA"
        
        private var baseCurrencyCode: String
        
        let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
        
        init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
            self.baseCurrencyCode = baseCurrencyCode
            self.completionHandler = completionHandler
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            if currencyCode == baseCurrencyCode {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, with dataSource: DataSource) {
            // 處理舊的 base currency
            do {
                if let oldSelectedBaseCurrencyIndexPath = dataSource.indexPath(for: baseCurrencyCode) {
                    if let oldSelectedBaseCurrencyCell = tableView.cellForRow(at: oldSelectedBaseCurrencyIndexPath){
                        oldSelectedBaseCurrencyCell.accessoryType = .none
                    }
                } else {
                    assertionFailure("")
                }
            }
            
            // 處理新的 base currency
            do {
                tableView.deselectRow(at: indexPath, animated: true)
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                
                if let newSelectedBaseCurrencyCode = dataSource.itemIdentifier(for: indexPath) {
                    baseCurrencyCode = newSelectedBaseCurrencyCode
                    completionHandler(newSelectedBaseCurrencyCode)
                } else {
                    assertionFailure("")
                }
            }
        }
        
        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath, with dataSource: DataSource) -> IndexPath? {
            dataSource.indexPath(for: baseCurrencyCode) == indexPath ? nil : indexPath
        }
    }
    
    
    
    
//    class SelectionCurrencyOfInterestViewModel: CurrencyTableViewModel {
//        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//            <#code#>
//        }
//
//
//        let title: String
//
//        private var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
//
//        private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
//
//        init(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
//             completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
//            title = "## 感興趣的貨幣"
//            self.currencyOfInterest = currencyOfInterest
//            self.completionHandler = completionHandler
//        }
//
//        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
//            if currencyOfInterest.contains(currencyCode) {
//                cell.accessoryType = .checkmark
//            } else {
//                cell.accessoryType = .none
//            }
//        }
//
//        func didTap(currencyCode: ResponseDataModel.CurrencyCode) {
//            if currencyOfInterest.contains(currencyCode) {
//                currencyOfInterest.remove(currencyCode)
//                completionHandler(currencyOfInterest)
//            } else {
//                currencyOfInterest.insert(currencyCode)
//                completionHandler(currencyOfInterest)
//            }
//        }
//    }
}
