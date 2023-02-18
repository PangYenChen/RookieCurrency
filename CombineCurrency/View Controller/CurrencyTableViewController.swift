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
    private let currencySubject: PassthroughSubject<Currency, Never>
    
    // MARK: - methods
    init?(coder: NSCoder, currencySubscriber: AnySubscriber<Currency, Never>) {
        
        currencySubject = PassthroughSubject()
        
        super.init(coder: coder)
        
        currencySubject.subscribe(currencySubscriber)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Table view delegate
extension CurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCurrency = Currency.allCases[indexPath.row]
        
        currencySubject.send(selectedCurrency)
        
        super.tableView(tableView, didSelectRowAt: indexPath)
    }
}
