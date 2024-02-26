import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - initializer
    required init?(coder: NSCoder) {
        resultModel = ResultModel()
        
        super.init(coder: coder, baseResultModel: resultModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultModel.completionHandler = { [unowned self] result in
            endRefreshingRefreshControlIfBegan()
            
            switch result {
                case .success(let (updatedTimestamp, sortedAnalyzedDataArray)):
                    dismissAlertIfPresented()
                    
                    populateTableViewWith(sortedAnalyzedDataArray)
                    
                    updateUpdatingStatusBarButtonItemFor(status: .idle(latestUpdateTimestamp: updatedTimestamp))
                case .failure(let failure):
                    dismissAlertIfPresented()
                    presentAlert(error: failure.underlyingError)
                    
                    updateUpdatingStatusBarButtonItemFor(status: .idle(latestUpdateTimestamp: failure.latestUpdateTimestamp))
            }
        }
    }
    
    // MARK: - life cycle
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        refreshControl?.beginRefreshing()
        resumeAutoRefreshing()
    }
    
    // MARK: - private property
    private let resultModel: ResultModel
    
    private var timer: Timer?
    
    // MARK: - kind of abstract methods
    override func refresh() {
        updateUpdatingStatusBarButtonItemFor(status: .process)
        resultModel.refresh()
    }
    
    override func setOrder(_ order: QuasiBaseResultModel.Order) {
        populateTableViewWith(resultModel.setOrder(order))
    }
    
    override func willShowSetting() {
        suspendAutoRefreshing()
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

// MARK: - private methods: auto refreshing
private extension ResultTableViewController {
    func resumeAutoRefreshing() {
        let autoRefreshTimeInterval: TimeInterval = 5
        timer = Timer.scheduledTimer(withTimeInterval: autoRefreshTimeInterval, repeats: true) { [unowned self] _ in
            refresh()
        }
        timer?.fire()
    }
    
    func suspendAutoRefreshing() {
        timer?.invalidate()
        timer = nil
    }
}
