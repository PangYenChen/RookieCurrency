import UIKit

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    // MARK: - private properties
    private let currencySelectionModel: CurrencySelectionModel
    
    // MARK: - life cycle
    init?(coder: NSCoder, currencySelectionModel: CurrencySelectionModel) {
        self.currencySelectionModel = currencySelectionModel
        
        super.init(coder: coder, baseCurrencySelectionModel: currencySelectionModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        currencySelectionModel.resultHandler = updateUIFor(result:)
        
        super.viewDidLoad()
    }
}
