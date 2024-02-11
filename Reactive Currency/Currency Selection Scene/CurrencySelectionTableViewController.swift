import UIKit
import Combine

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder, currencySelectionModel: CurrencySelectionModel) {
        self.currencySelectionModel = currencySelectionModel
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, baseCurrencySelectionModel: currencySelectionModel)
    }
    // MARK: - life cycle
    override func viewDidLoad() {
        currencySelectionModel.result
            .sink(receiveValue: self.updateUIFor(result:))
            .store(in: &anyCancellableSet)
        
        // super 的 viewDidLoad 給初始值，所以要在最後 call
        super.viewDidLoad()
    }
    
    // MARK: - instance properties
    private var anyCancellableSet: Set<AnyCancellable>
    
    private let currencySelectionModel: CurrencySelectionModel
}
