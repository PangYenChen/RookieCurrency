//
//  BaseCurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/18.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class BaseCurrencyTableViewController: UITableViewController {
    
    // MARK: - private properties
    private let currencies: [Currency]
    
    private var dataSource: DataSource!
    
    // MARK: - methods
    required init?(coder: NSCoder) {
        
        currencies = Currency.allCases
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
        }
        
        title = R.string.localizable.currency()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // table view data source
        do {
            dataSource = DataSource(tableView: tableView) { tableView, indexPath, currency in
                let identifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
                
                cell.textLabel?.text = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currency.code)
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.adjustsFontForContentSizeCategory = true
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
            
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(currencies)
            
            dataSource.apply(snapshot)
        }
    }
}

// MARK: - Table view delegate
extension BaseCurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencyTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        if searchText.isEmpty {
            snapshot.appendItems(currencies)
        } else {
            let filteredCurrencies = currencies
                .filter { currency in
                    [currency.code, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currency.code)]
                        .compactMap { $0 }
                        .contains { text in text.localizedStandardContains(searchText) }
                }
            snapshot.appendItems(filteredCurrencies)
        }
        
        dataSource.apply(snapshot)
    }
}

// MARK: - name space
private extension BaseCurrencyTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Currency>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Currency>
}
