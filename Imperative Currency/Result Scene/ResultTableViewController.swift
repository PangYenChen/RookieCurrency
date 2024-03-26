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
        
        resultModel.rateStatisticsHandler = populateTableViewWith
        resultModel.refreshStatusHandler = populateRefreshStatusBarButtonItemWith(status:)
        resultModel.dataAbsentCurrencyCodeSetHandler = presentDataAbsentAlertFor(currencyCodeSet:)
        resultModel.errorHandler = presentErrorAlert(error:)
        
        resultModel.resumeAutoRefresh()
    }
    
    // MARK: - private property
    private let resultModel: ResultModel
    
    // MARK: - override abstract methods
    override func setOrder(_ order: QuasiBaseResultModel.Order) {
        populateTableViewWith(resultModel.sortedRateStatistics(by: order))
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        populateTableViewWith(resultModel.filteredRateStatistics(by: searchText))
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        populateTableViewWith(resultModel.filteredRateStatistics(by: nil))
    }
}
