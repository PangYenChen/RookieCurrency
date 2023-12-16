import UIKit

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    // MARK: - private properties
    private var isFirstTimePopulate: Bool
    
    // MARK: - life cycle
    required init?(coder: NSCoder, currencySelectionModel: CurrencySelectionModelProtocol) {
        isFirstTimePopulate = true
        
        super.init(coder: coder, currencySelectionModel: currencySelectionModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hook methods
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortBarButtonItem.menu?.children.first?.subtitle = R.string.currencyScene.sortingWay(sortingMethod.localizedName, sortingOrder.localizedName)
        
        currencySelectionModel.set(sortingMethod: sortingMethod, andOrder: sortingOrder)
        
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
                                         sortingOrder: currencySelectionModel.getSortingOrder(),
                                         searchText: currencySelectionModel.getSearchText() ?? "", // TODO: 改成 optional
                                         isFirstTimePopulate: isFirstTimePopulate)
        if isFirstTimePopulate {
            isFirstTimePopulate = false
        }
    }
}

// MARK: - search bar delegate
extension CurrencySelectionTableViewController {
    final func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currencySelectionModel.set(searchText: searchText)
   
        populateTableViewIfPossible()
    }
    
    final func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        currencySelectionModel.set(searchText: nil)
        
        populateTableViewIfPossible()
    }
}
