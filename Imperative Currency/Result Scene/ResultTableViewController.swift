import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - initializer
    required init?(coder: NSCoder) {
        resultModel = ResultModel()
        
        super.init(coder: coder, baseResultModel: resultModel)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultModel.stateHandler = updateUIFor(_:)
    }
    
    // MARK: - private property
    private let resultModel: ResultModel
    
    // MARK: - kind of abstract methods
    override func updateStatus() {
        resultModel.updateState()
    }
    
    override func setOrder(_ order: BaseResultModel.Order) {
        resultModel.setOrder(order)
    }
}
