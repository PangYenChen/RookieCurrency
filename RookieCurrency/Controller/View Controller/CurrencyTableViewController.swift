//
//  CurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class CurrencyTableViewController: BaseCurrencyTableViewController {
    
    // MARK: - property
    private let completionHandler: (Currency) -> Void
    
    // MARK: - methods
    init?(coder: NSCoder, completionHandler: @escaping (Currency) -> Void) {
        self.completionHandler = completionHandler
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Table view delegate
extension CurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCurrency = Currency.allCases[indexPath.row]
        
        completionHandler(selectedCurrency)

        super.tableView(tableView, didSelectRowAt: indexPath)
    }
}
