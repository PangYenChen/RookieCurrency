//
//  CurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class CurrencyTableViewController: UITableViewController {
    
    // MARK: - property
    private let completionHandler: (Currency) -> Void
    
    private let currencies: [Currency]
    
    private var dataSource: DataSource!
    
    // MARK: - method
    init?(coder: NSCoder, completionHandler: @escaping (Currency) -> Void) {
        self.completionHandler = completionHandler
        currencies = Currency.allCases
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do { // table view data source
            dataSource = DataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
                let identifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
                
                cell.textLabel?.text = itemIdentifier.localizedString
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.adjustsFontForContentSizeCategory = true
                
                return cell
            }
            
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(currencies)
            
            dataSource.apply(snapshot)
        }
    }
}

// MARK: - Table view delegate
extension CurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCurrency = Currency.allCases[indexPath.row]
        
        completionHandler(selectedCurrency)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Search Bar Delegate
extension CurrencyTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        if searchText.isEmpty {
            snapshot.appendItems(currencies)
        } else {
            let filteredCurrencies = currencies
                .filter { currency in
                    [currency.code, currency.localizedString]
                        .contains { text in text.lowercased().contains(searchText.lowercased()) }
                }
            snapshot.appendItems(filteredCurrencies)
        }
        
        dataSource.apply(snapshot)
    }
}

// MARK: - name space
extension CurrencyTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Currency>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Currency>
}
