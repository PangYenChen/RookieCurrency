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
    
    // MARK: - property
    @IBOutlet private weak var sortBarButtonItem: UIBarButtonItem!
    
    #warning("看能不能拿掉")
    private var currencyCodeDescriptionDictionary: [String: String]
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    private let searchTest: PassthroughSubject<String, Never>
    
    private let viewModel: CurrencyTableViewModel
    
    private(set) var dataSource: DataSource!
    
    private let fetcher: Fetcher
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    init?(coder: NSCoder, viewModel: CurrencyTableViewModel) {
        
        currencyCodeDescriptionDictionary = [:]
        
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        
        searchTest = PassthroughSubject<String, Never>()
        
        self.viewModel = viewModel
        
        fetcher = Fetcher.shared
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
        
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
                    
                    switch sortingMethodAndOrder.value.method {
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
            
            // The the value of `sortingMethodAndOrder` could be changed between the call of `init` and `viewDidLoad`,
            // so we need to reset it in order to be consistent with the ascendingAction.state
            set(sortingMethod: .currencyName, sortingOrder: .ascending)
        }
        
        let refreshControlTriggered = PassthroughSubject<Void, Never>()
        
        // subscribe
        do {
            
            let symbolsResult = refreshControlTriggered
                .flatMap { [unowned self] in fetcher.publisher(for: Endpoint.SupportedSymbols()) }
                .convertOutputToResult()
                .share()
            
            symbolsResult
                .receive(on: DispatchQueue.main)
                .sink { [unowned self] _ in tableView.refreshControl?.endRefreshing() }
                .store(in: &anyCancellableSet)
            
            symbolsResult.resultFailure()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in self?.presentErrorAlert(error: error) }
                .store(in: &anyCancellableSet)
            
            symbolsResult.resultSuccess()
                .handleEvents(receiveOutput: { [unowned self] supportedSymbols in
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                })
                .combineLatest(sortingMethodAndOrder)
                .sink { [unowned self] (supportedSymbols, sortingMethodAndOrder) in
                    
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
                    
                    //                if !searchText.isEmpty {
                    //                    filteredCurrencyCodes = sortedCurrencyCodes
                    //                        .filter { currencyCode in
                    //                            [currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)]
                    //                                .compactMap { $0 }
                    //                                .contains { text in text.localizedStandardContains(searchText) }
                    //                        }
                    //                }
                    
                    snapshot.appendItems(filteredCurrencyCodes)
                    
                    dataSource.apply(snapshot)
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
}

// MARK: - private method
private extension CurrencyTableViewController {
    func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = sortingMethod.localizedName + sortingOrder.localizedName
        
        sortingMethodAndOrder.send((method: sortingMethod, order: sortingOrder))
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

// MARK: - view model
extension CurrencyTableViewController {
    
    class BaseCurrencySelectionViewModel: CurrencyTableViewModel {
        
        let title: String
        
        private let baseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
        
        init(baseCurrencyCode: String,
             selectedBaseCurrencyCode: AnySubscriber<ResponseDataModel.CurrencyCode, Never>) {
            title = R.string.localizable.baseCurrency()
            self.baseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(baseCurrencyCode)
            
            self.baseCurrencyCode
                .dropFirst()
                .subscribe(selectedBaseCurrencyCode)
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            cell.accessoryType = currencyCode == baseCurrencyCode.value ? .checkmark : .none
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, with dataSource: DataSource) {
            
            var identifiersNeedToBeReloaded: [ResponseDataModel.CurrencyCode] = []
            
            guard let newSelectedBaseCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
                assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
                return
            }
            
            identifiersNeedToBeReloaded.append(newSelectedBaseCurrencyCode)
            
            if let oldSelectedBaseCurrencyIndexPath = dataSource.indexPath(for: baseCurrencyCode.value),
               tableView.indexPathsForVisibleRows?.contains(oldSelectedBaseCurrencyIndexPath) == true {
                identifiersNeedToBeReloaded.append(baseCurrencyCode.value)
            }
            
            baseCurrencyCode.send(newSelectedBaseCurrencyCode)
            
            var snapshot = dataSource.snapshot()
            snapshot.reloadItems(identifiersNeedToBeReloaded)
            dataSource.apply(snapshot)
        }
        
        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath, with dataSource: DataSource) -> IndexPath? {
            dataSource.indexPath(for: baseCurrencyCode.value) == indexPath ? nil : indexPath
        }
    }
    
    class CurrencyOfInterestSelectionViewModel: CurrencyTableViewModel {

        let title: String

        private let currencyOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>

        init(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
             selectedCurrencyOfInterest: AnySubscriber<Set<ResponseDataModel.CurrencyCode>, Never>) {
            title = R.string.localizable.currencyOfInterest()
            self.currencyOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(currencyOfInterest)
            
            self.currencyOfInterest
                .dropFirst()
                .subscribe(selectedCurrencyOfInterest)
        }

        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            cell.accessoryType = currencyOfInterest.value.contains(currencyCode) ? .checkmark : .none
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, with dataSource: DataSource) {

            guard let selectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
                assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
                return
            }

            if currencyOfInterest.value.contains(selectedCurrencyCode) {
                currencyOfInterest.value.remove(selectedCurrencyCode)
            } else {
                currencyOfInterest.value.insert(selectedCurrencyCode)
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
