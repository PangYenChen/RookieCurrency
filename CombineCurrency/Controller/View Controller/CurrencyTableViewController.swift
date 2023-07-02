//
//  CurrencyTableViewController.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/17.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class CurrencyTableViewController: BaseCurrencyTableViewController {
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    private let searchText: CurrentValueSubject<String, Never>
    
    private let triggerRefreshControlSubject: PassthroughSubject<Void, Never>
    
    private var isFirstTimePopulate: Bool
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        
        searchText = CurrentValueSubject<String, Never>("")
        
        triggerRefreshControlSubject = PassthroughSubject<Void, Never>()
        
        isFirstTimePopulate = true
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, strategy: strategy)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Hook methods
    override func viewDidLoad() {

        // subscribe
        do {
            let symbolsResult = triggerRefreshControlSubject
                .flatMap { [unowned self] in fetcher.publisher(for: Endpoints.SupportedSymbols()) }
                .convertOutputToResult()
                .share()
            
            symbolsResult
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.tableView.refreshControl?.endRefreshing() }
                .store(in: &anyCancellableSet)
            
            symbolsResult.resultFailure()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in self?.presentErrorAlert(error: error) }
                .store(in: &anyCancellableSet)
            
            symbolsResult.resultSuccess()
                .combineLatest(sortingMethodAndOrder, searchText)
                .sink { [unowned self] (supportedSymbols, sortingMethodAndOrder, searchText) in
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                    
                    let (sortingMethod, sortingOrder) = sortingMethodAndOrder
                    
                    convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                                     sortingMethod: sortingMethod,
                                                     sortingOrder: sortingOrder,
                                                     searchText: searchText,
                                                     isFirstTimePopulate: isFirstTimePopulate)
                    isFirstTimePopulate = false
                }
                .store(in: &anyCancellableSet)
        }
        
        // super 的 viewDidLoad 給初始值，所以要在最後 call
        super.viewDidLoad()
    }
    
    override func getSortingMethod() -> BaseCurrencyTableViewController.SortingMethod {
        sortingMethodAndOrder.value.method
    }
    
    override func getSortingOrder() -> BaseCurrencyTableViewController.SortingOrder {
        sortingMethodAndOrder.value.order
    }
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = R.string.localizable.sortingWay(sortingMethod.localizedName, sortingOrder.localizedName)
        
        sortingMethodAndOrder.send((method: sortingMethod, order: sortingOrder))
    }
    
    override func triggerRefreshControl() {
        triggerRefreshControlSubject.send()
    }
}

// MARK: - search bar delegate
extension CurrencyTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText.send("")
    }
}

// MARK: - strategy
extension CurrencyTableViewController {
    
    class BaseCurrencySelectionStrategy: CurrencyTableStrategy {
        
        let title: String
        
        private let baseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
        
        var selectedCurrencies: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode.value] }
        
        let allowsMultipleSelection: Bool
        
        init(baseCurrencyCode: String,
             selectedBaseCurrencyCode: AnySubscriber<ResponseDataModel.CurrencyCode, Never>) {
            
            title = R.string.localizable.baseCurrency()
            self.baseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(baseCurrencyCode)
            allowsMultipleSelection = false
            // initialization completes
            
            self.baseCurrencyCode
                .dropFirst()
                .subscribe(selectedBaseCurrencyCode)
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            baseCurrencyCode.send(selectedCurrencyCode)
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            // allowsMultipleSelection = false，會呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
        }
    }
    
    class CurrencyOfInterestSelectionStrategy: CurrencyTableStrategy {

        let title: String
        
        private let currencyOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>

        var selectedCurrencies: Set<ResponseDataModel.CurrencyCode> { currencyOfInterest.value }
        
        let allowsMultipleSelection: Bool

        init(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
             selectedCurrencyOfInterest: AnySubscriber<Set<ResponseDataModel.CurrencyCode>, Never>) {
            
            title = R.string.localizable.currencyOfInterest()
            self.currencyOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(currencyOfInterest)
            allowsMultipleSelection = true
            // initialization completes
            
            self.currencyOfInterest
                .dropFirst()
                .subscribe(selectedCurrencyOfInterest)
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyOfInterest.value.insert(selectedCurrencyCode)
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyOfInterest.value.remove(deselectedCurrencyCode)
        }
    }
}
