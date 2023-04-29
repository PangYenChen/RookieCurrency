//
//  CurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class CurrencyTableViewController: BaseCurrencyTableViewController {
//
//    // MARK: - property
//    private let selectBaseCurrency: ((ResponseDataModel.CurrencyCode) -> Void)?
//
//    private let selectCurrencyOfInterest: ((Set<ResponseDataModel.CurrencyCode>) -> Void)?
//
//    // MARK: - methods
//    init?(coder: NSCoder,
//          selectionItem: SelectionItem,
//          selectBaseCurrency: ((ResponseDataModel.CurrencyCode) -> Void)? = nil,
//          selectCurrencyOfInterest: ((Set<ResponseDataModel.CurrencyCode>) -> Void)? = nil) {
//
//        self.selectBaseCurrency = selectBaseCurrency
//        self.selectCurrencyOfInterest = selectCurrencyOfInterest
//
//        super.init(coder: coder, selectionItem: selectionItem)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}


extension BaseCurrencyTableViewController {
    
    class SelectionBaseCurrencyViewModel: NSObject, UITableViewDelegate {
        
        let title: String
        
        private var baseCurrencyCode: String
        
        private var dataSource: DataSource!
        
        private var currencyCodeDescriptionDictionary: [String: String]
        
        private(set) var currencyCodes: [ResponseDataModel.CurrencyCode]
        
        private var sortingMethod: SortingMethod
        
        private var sortingOrder: SortingOrder
        
        private let fetcher: Fetcher
        
        private var searchText: String
        
        private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
        
        init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
            title = "## 選擇基準幣別"
            
            self.baseCurrencyCode = baseCurrencyCode
            
            currencyCodeDescriptionDictionary = [:]
            
            currencyCodes = []
            
            sortingMethod = .currencyName
            
            sortingOrder = .ascending
            
            fetcher = Fetcher.shared
            
            searchText = ""
            
            self.completionHandler = completionHandler
        }
        
        func configureDataSourceAndDeletate(tableView: UITableView) {
            
            tableView.refreshControl?.beginRefreshing()
            
            fetcher.fetch(Endpoint.SupportedSymbols()) { [unowned self] result in
                switch result {
                case .success(let supportedSymbols):
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                    currencyCodes = supportedSymbols.symbols.keys.map { $0 }
                        .sorted()
                    populateTableView()
                case .failure(let failure):
                    #warning("to be implemented")
                }
            }
            
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
                
                self.decorate(cell: cell, for: currencyCode)
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
            
            tableView.delegate = self
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            #warning("之後要抽出去")
            if currencyCode == baseCurrencyCode {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // 處理新的 base currency
            do {
                tableView.deselectRow(at: indexPath, animated: true)
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                
                if let newSelectedBaseCurrencyCode = dataSource.itemIdentifier(for: indexPath) {
                    baseCurrencyCode = newSelectedBaseCurrencyCode
                } else {
                    assertionFailure("")
                }
            }
            
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
            
        }
        
        func search(text searchText: String) {
            self.searchText = searchText
            populateTableView()
        }
        
        private func populateTableView() {
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
        
        func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
            self.sortingMethod = sortingMethod
            self.sortingOrder = sortingOrder
            
#warning("之後要帶資訊給 table view")
            populateTableView()
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

extension BaseCurrencyTableViewController.SelectionBaseCurrencyViewModel {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
}
