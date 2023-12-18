import UIKit

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    // MARK: - private properties
    private var isFirstTimePopulate: Bool
    
    private var imperativeCurrencySelectionModel: ImperativeCurrencySelectionModelProtocol
    
    // MARK: - life cycle
    init?(coder: NSCoder, currencySelectionModel: ImperativeCurrencySelectionModelProtocol) {
        isFirstTimePopulate = true
        imperativeCurrencySelectionModel = currencySelectionModel
        
        super.init(coder: coder, currencySelectionModel: currencySelectionModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        imperativeCurrencySelectionModel.stateHandler = { [weak self] result in
            guard let self else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.refreshControl?.endRefreshing()
            }
            
            switch result {
            case .success(let sortArray):
                populateTableViewWith(sortArray)
            case .failure(let failure):
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: failure)
                }
            }
        }
        
        super.viewDidLoad()
    }
}

// MARK: - private method
private extension CurrencySelectionTableViewController {
    func populateTableViewWith(_ array: [ResponseDataModel.CurrencyCode]) {
        populateTableViewWith(array, shouldScrollToFirstSelectedItem: isFirstTimePopulate)
        
        if isFirstTimePopulate {
            isFirstTimePopulate = false
        }
    }
}
