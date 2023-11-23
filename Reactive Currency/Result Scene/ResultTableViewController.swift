import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored properties
    private let model: ResultModel
    
    private let enableModelAutoUpdate: PassthroughSubject<Bool, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
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
            .sink(receiveValue: self.updateUIFor(_:))
            .store(in: &anyCancellableSet)
        
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        self.enableModelAutoUpdate.send(false)
        // TODO: 抽到 super class
        return SettingTableViewController(coder: coder,
                                          model: model.settingModel())
    }
}
