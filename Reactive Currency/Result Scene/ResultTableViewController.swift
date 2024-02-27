import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - initializer
    required init?(coder: NSCoder) {
        resultModel = ResultModel()
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, baseResultModel: resultModel)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultModel.analyzedDataArray
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: populateTableViewWith)
            .store(in: &anyCancellableSet)
        
        resultModel.refreshStatus
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: populateRefreshStatusBarButtonItemWith(status:))
            .store(in: &anyCancellableSet)
        
        resultModel.error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: presentErrorAlert(error:))
            .store(in: &anyCancellableSet)
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        refreshControl?.beginRefreshing()
        resultModel.refresh()
    }
    
    // MARK: - private properties
    private let resultModel: ResultModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - kind of abstract methods
    override func setOrder(_ order: BaseResultModel.Order) {
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
