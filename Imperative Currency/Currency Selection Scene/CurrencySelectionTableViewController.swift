import UIKit

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    // MARK: - private properties
    private var imperativeCurrencySelectionModel: ImperativeCurrencySelectionModelProtocol
    
    // MARK: - life cycle
    init?(coder: NSCoder, currencySelectionModel: ImperativeCurrencySelectionModelProtocol) {
        imperativeCurrencySelectionModel = currencySelectionModel
        
        super.init(coder: coder, currencySelectionModel: currencySelectionModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        imperativeCurrencySelectionModel.resultHandler = updateUIFor(result:)
        
        super.viewDidLoad()
    }
}
