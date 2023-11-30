import UIKit

class CurrencyTableViewController: BaseCurrencyTableViewController {
    
    // MARK: - private properties
    private var sortingMethod: SortingMethod
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String
    
    private var isFirstTimePopulate: Bool
    
    // MARK: - life cycle
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        sortingMethod = .currencyName
        
        sortingOrder = .ascending
        
        searchText = ""
        
        isFirstTimePopulate = true
        
        super.init(coder: coder, strategy: strategy)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hook methods
    override func getSortingMethod() -> BaseCurrencyTableViewController.SortingMethod {
        sortingMethod
    }
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = R.string.currencyScene.sortingWay(sortingMethod.localizedName, sortingOrder.localizedName)
        
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        
        populateTableViewIfPossible()
    }
    
    override func triggerRefreshControl() {
        AppUtility.fetchSupportedSymbols { [weak self] result in
            guard let self else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
            
            switch result {
            case .success(let supportedSymbols):
                currencyCodeDescriptionDictionary = supportedSymbols
                
                populateTableViewIfPossible()
            case .failure(let failure):
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: failure)
                }
            }
        }
    }
}

// MARK: - private method
private extension CurrencyTableViewController {
    func populateTableViewIfPossible() {
        guard let currencyCodeDescriptionDictionary else {
            return
        }
        
        convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                         sortingMethod: self.sortingMethod,
                                         sortingOrder: self.sortingOrder,
                                         searchText: searchText,
                                         isFirstTimePopulate: isFirstTimePopulate)
        if isFirstTimePopulate {
            isFirstTimePopulate = false
        }
    }
}

// MARK: - search bar delegate
extension CurrencyTableViewController {
    final func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
   
        populateTableViewIfPossible()
    }
    
    final func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText = ""
        
        populateTableViewIfPossible()
    }
}

// MARK: - strategy
extension CurrencyTableViewController {
    
    final class BaseCurrencySelectionStrategy: CurrencyTableStrategy {
        
        let title: String
        
        private var baseCurrencyCode: String
        
        var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode] }
        
        let allowsMultipleSelection: Bool
        
        private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
        
        init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
            title = R.string.share.baseCurrency()
            self.baseCurrencyCode = baseCurrencyCode
            allowsMultipleSelection = false
            self.completionHandler = completionHandler
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            
            completionHandler(selectedCurrencyCode)
            baseCurrencyCode = selectedCurrencyCode
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            // allowsMultipleSelection = false，會呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
        }
    }
    
    final class CurrencyOfInterestSelectionStrategy: CurrencyTableStrategy {
        
        let title: String
        
        private var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
        
        var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterest }
        
        let allowsMultipleSelection: Bool
        
        private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
        
        init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
             completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
            title = R.string.share.currencyOfInterest()
            self.currencyCodeOfInterest = currencyCodeOfInterest
            allowsMultipleSelection = true
            self.completionHandler = completionHandler
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyCodeOfInterest.insert(selectedCurrencyCode)
            completionHandler(currencyCodeOfInterest)
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyCodeOfInterest.remove(deselectedCurrencyCode)
            completionHandler(currencyCodeOfInterest)
        }
    }
}
