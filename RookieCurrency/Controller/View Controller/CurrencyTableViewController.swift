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
    private let selectBaseCurrency: ((ResponseDataModel.CurrencyCode) -> Void)?
    
    private let selectCurrencyOfInterest: ((Set<ResponseDataModel.CurrencyCode>) -> Void)?
    
    // MARK: - methods
    init?(coder: NSCoder,
          selectionItem: SelectionItem,
          selectBaseCurrency: ((ResponseDataModel.CurrencyCode) -> Void)? = nil,
          selectCurrencyOfInterest: ((Set<ResponseDataModel.CurrencyCode>) -> Void)? = nil) {
        
        self.selectBaseCurrency = selectBaseCurrency
        self.selectCurrencyOfInterest = selectCurrencyOfInterest
        
        super.init(coder: coder, selectionItem: selectionItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Table view delegate
extension CurrencyTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCurrencyCode = currencyCodes[indexPath.row]
        
        switch selectionItem {
        case .baseCurrency:
            selectBaseCurrency?(selectedCurrencyCode)
            
        case .currencyOfInterest(var currencyOfInterest):
            guard let cell = tableView.cellForRow(at: indexPath) else {
                assertionFailure("table view should get the selected cell")
                return
            }

            if currencyOfInterest.contains(selectedCurrencyCode) {
                currencyOfInterest.remove(selectedCurrencyCode)
                cell.accessoryType = .none
            } else {
                currencyOfInterest.insert(selectedCurrencyCode)
                cell.accessoryType = .checkmark
            }

            selectionItem = .currencyOfInterest(currencyOfInterest)

            tableView.deselectRow(at: indexPath, animated: true)
            
            selectCurrencyOfInterest?(currencyOfInterest)
        }
    }
}
