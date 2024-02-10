import UIKit

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder, currencySelectionModel: CurrencySelectionModel) {
        self.currencySelectionModel = currencySelectionModel
        
        super.init(coder: coder, baseCurrencySelectionModel: currencySelectionModel)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        currencySelectionModel.resultHandler = updateUIFor(result:)
        
        super.viewDidLoad()
    }
    
    // MARK: - private properties
    private let currencySelectionModel: CurrencySelectionModel
}
