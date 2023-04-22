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
    private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
    
    // MARK: - methods
    init?(coder: NSCoder,
          selectionItem: SelectionItem,
          completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
        
        self.completionHandler = completionHandler
        
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
        
        completionHandler(selectedCurrencyCode)

        super.tableView(tableView, didSelectRowAt: indexPath)
    }
}
