import UIKit

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    // MARK: - private properties
    private var sortingOrder: SortingOrder
    
    private var searchText: String
    
    private var isFirstTimePopulate: Bool
    
    // MARK: - life cycle
    required init?(coder: NSCoder, currencySelectionModel: CurrencySelectionModelProtocol) {
    
        sortingOrder = .ascending
        
        searchText = ""
        
        isFirstTimePopulate = true
        
        super.init(coder: coder, currencySelectionModel: currencySelectionModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hook methods
    override func getSortingMethod() -> SortingMethod {
        currencySelectionModel.getSortingMethod()
    }
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = R.string.currencyScene.sortingWay(sortingMethod.localizedName, sortingOrder.localizedName)
        
        currencySelectionModel.set(sortingMethod: sortingMethod)
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
private extension CurrencySelectionTableViewController {
    func populateTableViewIfPossible() {
        guard let currencyCodeDescriptionDictionary else {
            return
        }
        
        convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                         sortingMethod: currencySelectionModel.getSortingMethod(),
                                         sortingOrder: self.sortingOrder,
                                         searchText: searchText,
                                         isFirstTimePopulate: isFirstTimePopulate)
        if isFirstTimePopulate {
            isFirstTimePopulate = false
        }
    }
}

// MARK: - search bar delegate
extension CurrencySelectionTableViewController {
    final func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
   
        populateTableViewIfPossible()
    }
    
    final func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText = ""
        
        populateTableViewIfPossible()
    }
}
