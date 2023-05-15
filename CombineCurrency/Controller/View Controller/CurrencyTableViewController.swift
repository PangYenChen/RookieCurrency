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

    private let sortingMethod: CurrentValueSubject<SortingMethod, Never>
    
    private let sortingOrder: PassthroughSubject<SortingOrder, Never>
    
    private let searchTest: PassthroughSubject<String, Never>
    
    private let viewModel: CurrencyTableViewModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    init?(coder: NSCoder, viewModel: CurrencyTableViewModel) {
        
        sortingMethod = CurrentValueSubject<SortingMethod, Never>(.currencyName)
        
        sortingOrder = PassthroughSubject<SortingOrder, Never>()
        
        searchTest = PassthroughSubject<String, Never>()
        
        self.viewModel = viewModel
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
        
        title = viewModel.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetcher.publisher(for: Endpoint.SupportedSymbols())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [unowned self] completion in
                    switch completion {
                    case .finished:
                        //                    tableView.refreshControl?.endRefreshing()
                        #warning("要結束下拉更新")
                    case .failure(let error):
                        presentErrorAlert(error: error)
                    }
                },
                receiveValue: { [unowned self] supportedSymbols in
                    currencyCodeDescriptionDictionary = supportedSymbols.symbols
                }
            )
            .store(in: &anyCancellableSet)
    }
    
    
}

// MARK: - view model
extension CurrencyTableViewController {
    
    class BaseCurrencySelectionViewModel: CurrencyTableViewModel {
        
        let title: String
        
        private var baseCurrencyCode: String
        
        private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
        
        init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
            title = R.string.localizable.baseCurrency()
            self.baseCurrencyCode = baseCurrencyCode
            self.completionHandler = completionHandler
        }
        
        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
            cell.accessoryType = currencyCode == baseCurrencyCode ? .checkmark : .none
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, with dataSource: DataSource) {
            
            var identifiersNeedToBeReloaded: [ResponseDataModel.CurrencyCode] = []
            
            guard let newSelectedBaseCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
                assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
                return
            }
            
            identifiersNeedToBeReloaded.append(newSelectedBaseCurrencyCode)
            
            if let oldSelectedBaseCurrencyIndexPath = dataSource.indexPath(for: baseCurrencyCode),
               tableView.indexPathsForVisibleRows?.contains(oldSelectedBaseCurrencyIndexPath) == true {
                identifiersNeedToBeReloaded.append(baseCurrencyCode)
            }
            
            baseCurrencyCode = newSelectedBaseCurrencyCode
            
            var snapshot = dataSource.snapshot()
            snapshot.reloadItems(identifiersNeedToBeReloaded)
            dataSource.apply(snapshot)
            
            completionHandler(newSelectedBaseCurrencyCode)
        }
        
        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath, with dataSource: DataSource) -> IndexPath? {
            dataSource.indexPath(for: baseCurrencyCode) == indexPath ? nil : indexPath
        }
    }
    
//    class CurrencyOfInterestSelectionViewModel: CurrencyTableViewModel {
//
//        let title: String
//
//        private var currencyOfInterest: Set<ResponseDataModel.CurrencyCode>
//
//        private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
//
//        init(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
//             completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
//            title = R.string.localizable.currencyOfInterest()
//            self.currencyOfInterest = currencyOfInterest
//            self.completionHandler = completionHandler
//        }
//
//        func decorate(cell: UITableViewCell, for currencyCode: ResponseDataModel.CurrencyCode) {
//            cell.accessoryType = currencyOfInterest.contains(currencyCode) ? .checkmark : .none
//        }
//
//        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, with dataSource: DataSource) {
//
//            guard let selectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
//                assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
//                return
//            }
//
//            if currencyOfInterest.contains(selectedCurrencyCode) {
//                currencyOfInterest.remove(selectedCurrencyCode)
//            } else {
//                currencyOfInterest.insert(selectedCurrencyCode)
//            }
//
//            var snapshot = dataSource.snapshot()
//            snapshot.reloadItems([selectedCurrencyCode])
//            dataSource.apply(snapshot)
//        }
//
//        func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath, with dataSource: DataSource) -> IndexPath? {
//            indexPath
//        }
//    }
}
