//
//  CurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class CurrencyTableViewController: BaseCurrencyTableViewController {
//
//    // MARK: - property
//    private let selectBaseCurrency: ((ResponseDataModel.CurrencyCode) -> Void)?
//
//    private let selectCurrencyOfInterest: ((Set<ResponseDataModel.CurrencyCode>) -> Void)?
//
//    // MARK: - methods
//    init?(coder: NSCoder,
//          selectionItem: SelectionItem,
//          selectBaseCurrency: ((ResponseDataModel.CurrencyCode) -> Void)? = nil,
//          selectCurrencyOfInterest: ((Set<ResponseDataModel.CurrencyCode>) -> Void)? = nil) {
//
//        self.selectBaseCurrency = selectBaseCurrency
//        self.selectCurrencyOfInterest = selectCurrencyOfInterest
//
//        super.init(coder: coder, selectionItem: selectionItem)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}


extension BaseCurrencyTableViewController {
    
    class SelectionBaseCurrencyViewModel: CurrencyTableViewModel {
        
        let title: String
        
        private let baseCurrencyCode: String
        
        private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
        
        init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
            title = "## 選擇基準幣別"
            
            self.baseCurrencyCode = baseCurrencyCode
            
            self.completionHandler = completionHandler
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            if currencyCode == baseCurrencyCode {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        func didTap(currencyCode: ResponseDataModel.CurrencyCode) {
            completionHandler(currencyCode)
        }
    }
    
    class SelectionCurrencyOfInterestViewModel: CurrencyTableViewModel {
    
        let title: String
        
        private var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
        
        private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
        
        init(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
             completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
            title = "## 感興趣的貨幣"
            self.currencyOfInterest = currencyOfInterest
            self.completionHandler = completionHandler
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            if currencyOfInterest.contains(currencyCode) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        func didTap(currencyCode: ResponseDataModel.CurrencyCode) {
            if currencyOfInterest.contains(currencyCode) {
                currencyOfInterest.remove(currencyCode)
                completionHandler(currencyOfInterest)
            } else {
                currencyOfInterest.insert(currencyCode)
                completionHandler(currencyOfInterest)
            }
        }
    }
}
