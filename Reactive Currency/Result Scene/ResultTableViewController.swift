import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored properties
    private let model: ResultModel
    
    private let enableModelAutoUpdate: PassthroughSubject<Bool, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    private var latestUpdateTime: Int?
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        model = ResultModel()
        
        enableModelAutoUpdate = PassthroughSubject<Bool, Never>()
        enableModelAutoUpdate.receive(subscriber: model.enableAutoUpdateState)
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, baseResultModel: model)
    }
    
    required init?(coder: NSCoder, baseResultModel: BaseResultModel) {
        fatalError("init(coder:baseResultModel:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.state
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] state in
                // TODO: 抽到 super class
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
            .store(in: &anyCancellableSet)
        
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        self.enableModelAutoUpdate.send(false)
        
        return SettingTableViewController(coder: coder,
                                          model: model.settingModel())
    }
}
