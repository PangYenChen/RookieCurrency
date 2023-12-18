import UIKit
import Combine

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    private let reactiveCurrencySelectionModel: ReactiveCurrencySelectionModel
    
    // MARK: - life cycle
    init?(coder: NSCoder, currencySelectionModel: ReactiveCurrencySelectionModel) {
        
        reactiveCurrencySelectionModel = currencySelectionModel
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, currencySelectionModel: currencySelectionModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        reactiveCurrencySelectionModel.state
            .sink(receiveValue: self.updateUIFor(result:))
            .store(in: &anyCancellableSet)
        
        // super 的 viewDidLoad 給初始值，所以要在最後 call
        super.viewDidLoad()
    }
}
