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
        
        resultModel.state
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: self.updateUIFor(_:))
            .store(in: &anyCancellableSet)
    }
    
    // MARK: - private properties
    private let resultModel: ResultModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - kind of abstract methods
    override func refresh() {
        resultModel.refresh()
    }
    
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
