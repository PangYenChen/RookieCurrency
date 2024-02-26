import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - initializer
    required init?(coder: NSCoder) {
        resultModel = ResultModel()
        
        super.init(coder: coder, baseResultModel: resultModel)
    }
    
    // MARK: - life cycle
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        refreshControl?.beginRefreshing()
        refresh()
    }
    
    // MARK: - private property
    private let resultModel: ResultModel
    
    // MARK: - kind of abstract methods
    override func refresh() {
        resultModel.refresh { [unowned self] result in
            endRefreshingRefreshControlIfBegan()
            
            switch result {
                case .success(let (updatedTimestamp, analyzedSortedDataArray)):
                    populateTableViewWith(analyzedSortedDataArray)
                    
                    populateUpdatingStatusBarButtonItemWith(updatedTimestamp)
                    
                case .failure(let failure):
                    dismissAlertIfPresented()
                    presentAlert(error: failure.underlyingError)
                    
                    populateUpdatingStatusBarButtonItemWith(failure.latestUpdateTimestamp)
            }
        }
    }
    
    override func setOrder(_ order: QuasiBaseResultModel.Order) {
        resultModel.setOrder(order)
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        resultModel.setSearchText(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resultModel.setSearchText(nil)
    }
}
