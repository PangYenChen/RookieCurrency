//
//  BaseCurrencyTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/18.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

/// 這裡的 base 是 base class 的意思，不是基準貨幣
class BaseCurrencyTableViewController: UITableViewController {
    
    // MARK: - methods
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
        }
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencyTableViewController: UISearchBarDelegate {}

// MARK: - name space
extension BaseCurrencyTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
    enum SortingMethod {
        case currencyName
        case currencyCode
        case currencyNameZhuyin
        
        var localizedName: String {
            switch self {
            case .currencyName: return R.string.localizable.currencyName()
            case .currencyCode: return R.string.localizable.currencyCode()
            case .currencyNameZhuyin: return R.string.localizable.currencyZhuyin()
            }
        }
    }
    
    enum SortingOrder {
        case ascending
        case descending
        
        var localizedName: String {
            switch self {
            case .ascending: return R.string.localizable.ascending()
            case .descending: return R.string.localizable.decreasing()
            }
        }
    }
}

// MARK: - Error Alert Presenter
extension BaseCurrencyTableViewController: ErrorAlertPresenter {}

// MARK: - strategy
protocol CurrencyTableStrategy {
    
    var title: String { get }
    
    var selectedCurrencies: Set<ResponseDataModel.CurrencyCode> { get }
    
    var allowsMultipleSelection: Bool { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
}
