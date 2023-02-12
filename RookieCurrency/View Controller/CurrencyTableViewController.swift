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
    
    // MARK: - method
    init?(coder: NSCoder, completionHandler: @escaping (Currency) -> Void) {
        self.completionHandler = completionHandler
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Table view data source
extension CurrencyTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Currency.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = R.reuseIdentifier.currencyCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.textLabel?.text = Currency.allCases[indexPath.row].name
        
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
