import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder) {
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
}
