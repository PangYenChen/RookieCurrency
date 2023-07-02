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
    
    private var isFirstTimePopulate: Bool
    
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        sortingMethod = .currencyName
        
        sortingOrder = .ascending
        
        searchText = ""
        
        isFirstTimePopulate = true
        
        super.init(coder: coder, strategy: strategy)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                         sortingMethod: self.sortingMethod,
                                         sortingOrder: self.sortingOrder,
                                         searchText: searchText,
                                         isFirstTimePopulate: isFirstTimePopulate)
        if isFirstTimePopulate {
            isFirstTimePopulate = false
        }
    }
    
    override func triggerRefreshControl() {
        fetcher.fetch(Endpoints.SupportedSymbols()) { [weak self] result in
            guard let self else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
            
            switch result {
            case .success(let supportedSymbols):
                currencyCodeDescriptionDictionary = supportedSymbols.symbols
                convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                                 sortingMethod: sortingMethod,
                                                 sortingOrder: sortingOrder,
                                                 searchText: searchText,
                                                 isFirstTimePopulate: isFirstTimePopulate)
                isFirstTimePopulate = false
            case .failure(let failure):
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: failure)
                }
            }
        }
    }
}

// MARK: - search bar delegate
extension CurrencyTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                         sortingMethod: sortingMethod,
                                         sortingOrder: sortingOrder,
                                         searchText: self.searchText,
                                         isFirstTimePopulate: isFirstTimePopulate)
        isFirstTimePopulate = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText = ""
        convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                         sortingMethod: sortingMethod,
                                         sortingOrder: sortingOrder,
                                         searchText: searchText,
                                         isFirstTimePopulate: isFirstTimePopulate)
        isFirstTimePopulate = false
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
