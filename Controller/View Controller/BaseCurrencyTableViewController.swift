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
    private var currencyCodeDescriptionDictionary: [String: String]
    
    private(set) var currencyCodes: [ResponseDataModel.CurrencyCode]
    
    private var dataSource: DataSource!
    
    private let selectionItem: SelectionItem
    
    private let fetcher: Fetcher
    
    // MARK: - methods
    init?(coder: NSCoder, selectionItem: SelectionItem) {
        
        currencyCodeDescriptionDictionary = [:]
        
        currencyCodes = []
        
        self.selectionItem = selectionItem
        
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
                
                let localizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)
                let serverCurrencyDescription = currencyCodeDescriptionDictionary[currencyCode]
                
                cell.textLabel?.text = localizedCurrencyDescription ?? serverCurrencyDescription
                
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.adjustsFontForContentSizeCategory = true
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
            
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(currencyCodes)
            
            dataSource.apply(snapshot)
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
                    updateTableView()
                case .failure(let failure):
                    presentErrorAlert(error: failure)
                }
            }
        }
    }
    
    // MARK: - private method
    private func updateTableView(for searchText: String = "") {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        if searchText.isEmpty {
            snapshot.appendItems(currencyCodes)
        } else {
            let filteredCurrencies = currencyCodes
                .filter { currencyCode in
                    [currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)]
                        .compactMap { $0 }
                        .contains { text in text.localizedStandardContains(searchText) }
                }
            snapshot.appendItems(filteredCurrencies)
        }
        
        dataSource.apply(snapshot)
    }
}

// MARK: - Table view delegate
extension BaseCurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch selectionItem {
        case .baseCurrency:
            navigationController?.popViewController(animated: true)
        case .currencyOfInterest:
            break
        }
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencyTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateTableView(for: searchText)
    }
}

// MARK: - private name space
private extension BaseCurrencyTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
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
