import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored property
    private let model: ResultModel
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        model = ResultModel()
        
        super.init(coder: coder, baseResultModel: model)
    }
    
    required init?(coder: NSCoder, baseResultModel: BaseResultModel) {
        fatalError("init(coder:baseResultModel:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.stateHandler = updateUIFor(_:)
    }
    
    // MARK: - navigation
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        SettingTableViewController(coder: coder, model: model.settingModel())
    }
}
