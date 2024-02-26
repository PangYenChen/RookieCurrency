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
    override func updateStatus() {
        resultModel.updateState()
    }
}
