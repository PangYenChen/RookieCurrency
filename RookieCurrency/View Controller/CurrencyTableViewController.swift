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
    
    private var filteredCurrencies: [Currency]
    
    // MARK: - method
    init?(coder: NSCoder, completionHandler: @escaping (Currency) -> Void) {
        self.completionHandler = completionHandler
        currencies = Currency.allCases
        filteredCurrencies = currencies
        
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
}

// MARK: - Table view data source
extension CurrencyTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredCurrencies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = R.reuseIdentifier.currencyCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.textLabel?.text = filteredCurrencies[indexPath.row].localizedString
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        return cell
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

// MARK: - type something
extension CurrencyTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredCurrencies = currencies
        } else {
            filteredCurrencies = currencies
                .filter { currency in
                    [currency.code, currency.localizedString]
                        .contains { text in text.lowercased().contains(searchText.lowercased()) }
                }
        }
        
        tableView.reloadData()
    }
}
