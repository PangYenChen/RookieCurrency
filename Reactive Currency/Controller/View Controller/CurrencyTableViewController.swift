import UIKit
import Combine

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    private let reactiveCurrencySelectionModel: ReactiveCurrencySelectionModel
    
    // MARK: - life cycle
    init?(coder: NSCoder, currencySelectionModel: ReactiveCurrencySelectionModel) {
        
        reactiveCurrencySelectionModel = currencySelectionModel
        
        isFirstTimePopulate = true
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, currencySelectionModel: currencySelectionModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // subscribe
        do {
            let symbolsResult = reactiveCurrencySelectionModel.state
                .share()
            
            symbolsResult
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.tableView.refreshControl?.endRefreshing() }
                .store(in: &anyCancellableSet)
            
            symbolsResult.resultFailure()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in self?.presentAlert(error: error) }
                .store(in: &anyCancellableSet)
            
            // TODO: 注意下面的邏輯 應該有漏
            symbolsResult.resultSuccess()
                .sink { [unowned self] array in
                    
                    populateTableViewWith(array, shouldScrollToFirstSelectedItem: isFirstTimePopulate)
                    
                    if isFirstTimePopulate {
                        isFirstTimePopulate = false
                    }
                }
                .store(in: &anyCancellableSet)
        }
        
        // super 的 viewDidLoad 給初始值，所以要在最後 call
        super.viewDidLoad()
    }
}
