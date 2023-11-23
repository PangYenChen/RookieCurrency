import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored property
    private let resultModel: ResultModel
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        resultModel = ResultModel()
        
        super.init(coder: coder, baseResultModel: resultModel)
    }
    
    required init?(coder: NSCoder, baseResultModel: BaseResultModel) {
        fatalError("init(coder:baseResultModel:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultModel.stateHandler = updateUIFor(_:)
    }
}
