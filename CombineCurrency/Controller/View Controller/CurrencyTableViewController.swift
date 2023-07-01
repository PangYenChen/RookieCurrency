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
    
    private var isReceivingFirstData: Bool
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        
        searchText = CurrentValueSubject<String, Never>("")
        
        isReceivingFirstData = true
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, strategy: strategy)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Hook methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControlTriggered = PassthroughSubject<Void, Never>()
        
        // subscribe
        do {
            
            let symbolsResult = refreshControlTriggered
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
                .handleEvents(receiveOutput: { [unowned self] supportedSymbols in
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                })
                .combineLatest(sortingMethodAndOrder, searchText)
                .sink { [unowned self] (supportedSymbols, sortingMethodAndOrder, searchText) in
                    
                    let (sortingMethod, sortingOrder) = sortingMethodAndOrder
                    
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
                .store(in: &anyCancellableSet)
        }
        
        // table view refresh controller
        do {
            tableView.refreshControl = UIRefreshControl()
            
            let action = UIAction { _ in refreshControlTriggered.send() }
            tableView.refreshControl?.addAction(action, for: .primaryActionTriggered)
            
            tableView.refreshControl?.beginRefreshing()
            tableView.refreshControl?.sendActions(for: .primaryActionTriggered)
        }
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
