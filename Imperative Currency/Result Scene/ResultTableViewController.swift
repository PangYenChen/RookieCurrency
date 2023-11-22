import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored property
    private let model: ResultModel
    
    private var latestUpdateTime: Int?
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        model = ResultModel()
        latestUpdateTime = nil
        
        super.init(coder: coder, baseResultModel: model)
    }
    
    required init?(coder: NSCoder, baseResultModel: BaseResultModel) {
        fatalError("init(coder:baseResultModel:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.stateHandler = self.updateUIFor(_:)
        model.resumeAutoUpdatingState()
    }
    
    // MARK: - navigation
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        model.suspendAutoUpdatingState()
        
        let userSetting = (numberOfDay: model.numberOfDays, baseCurrency: model.baseCurrencyCode, currencyOfInterest: model.currencyCodeOfInterest)
        
        return SettingTableViewController(
            coder: coder,
            userSetting: userSetting
        ) { [unowned self] editedNumberOfDays, editedBaseCurrencyCode, editedCurrencyCodeOfInterest in
            model.resumeAutoUpdatingStateFor(numberOfDays: editedNumberOfDays,
                                             baseCurrencyCode: editedBaseCurrencyCode,
                                             currencyCodeOfInterest: editedCurrencyCodeOfInterest,
                                             completionHandler: updateUIFor(_:))
        } cancelCompletionHandler: { [unowned self] in
            // TODO:
//            model.resumeAutoUpdatingState(completionHandler: updateUIFor(_:))
        }
    }
}

// MARK: - private method
private extension ResultTableViewController {
    func updateUIFor(_ state: BaseResultModel.State) {
        switch state {
        case .updating:
            updatingStatusBarButtonItem.title = R.string.resultScene.updating()
            
        case .updated(let timestamp, let analyzedDataArray):
            self.latestUpdateTime = timestamp
            populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
            populateTableViewWith(analyzedDataArray)
            
            if tableView.refreshControl?.isRefreshing == true {
                tableView.refreshControl?.endRefreshing()
            }
            
        case .sorted(let analyzedDataArray):
            populateTableViewWith(analyzedDataArray)
            
        case .failure(let error):
            populateUpdatingStatusBarButtonItemWith(self.latestUpdateTime)
            presentAlert(error: error)
            
            if tableView.refreshControl?.isRefreshing == true {
                tableView.refreshControl?.endRefreshing()
            }
        }
    }
}
