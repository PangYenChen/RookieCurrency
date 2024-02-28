import UIKit

final class ResultTableViewController: BaseResultTableViewController {
    // MARK: - initializer
    required init?(coder: NSCoder) {
        resultModel = ResultModel()
        
        super.init(coder: coder, baseResultModel: resultModel)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultModel.analyzedDataArrayHandler = populateTableViewWith
        resultModel.refreshStatusHandler = populateRefreshStatusBarButtonItemWith(status:)
        resultModel.errorHandler = presentErrorAlert(error:)
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        refreshControl?.beginRefreshing()
        resultModel.refresh()
    }
    
    // MARK: - private property
    private let resultModel: ResultModel
    
    private var timer: Timer?
    
    // MARK: - override abstract methods
    override func setOrder(_ order: QuasiBaseResultModel.Order) {
        populateTableViewWith(resultModel.setOrder(order))
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        populateTableViewWith(resultModel.setSearchText(searchText))
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        populateTableViewWith(resultModel.setSearchText(nil))
    }
}
