import UIKit
import Combine

final class CurrencySelectionTableViewController: BaseCurrencySelectionTableViewController {
    private let searchText: CurrentValueSubject<String, Never>
    
    private let triggerRefreshControlSubject: PassthroughSubject<Void, Never>
    
    // TODO: 看這個能不能用 publisher 之類的取代
    private var isFirstTimePopulate: Bool
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - life cycle
    required init?(coder: NSCoder, currencySelectionModel: CurrencySelectionModelProtocol) {
        searchText = CurrentValueSubject<String, Never>("")
        
        triggerRefreshControlSubject = PassthroughSubject<Void, Never>()
        
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
            
            // TODO:
//            sortingMethodAndOrder
//                .sink { [unowned self] (sortingMethod, sortingOrder) in
//                    sortBarButtonItem.menu?.children.first?.subtitle = R.string.currencyScene.sortingWay(sortingMethod.localizedName, sortingOrder.localizedName)
//                }
//                .store(in: &anyCancellableSet)
            
            let symbolsResult = triggerRefreshControlSubject
                .flatMap { _ in AppUtility.supportedSymbolsPublisher().convertOutputToResult() }
                .share()
            
            symbolsResult
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.tableView.refreshControl?.endRefreshing() }
                .store(in: &anyCancellableSet)
            
            symbolsResult.resultFailure()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in self?.presentAlert(error: error) }
                .store(in: &anyCancellableSet)
            
            // TODO:
//            symbolsResult.resultSuccess()
//                .combineLatest(currencySelectionModel.sortingMethodAndOrder, searchText)
//                .sink { [unowned self] (supportedSymbols, sortingMethodAndOrder, searchText) in
//                    currencyCodeDescriptionDictionary = supportedSymbols
//                    
//                    let (sortingMethod, sortingOrder) = sortingMethodAndOrder
//                    
//                    convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: supportedSymbols,
//                                                     sortingMethod: sortingMethod,
//                                                     sortingOrder: sortingOrder,
//                                                     searchText: searchText,
//                                                     isFirstTimePopulate: isFirstTimePopulate)
//                    isFirstTimePopulate = false
//                }
//                .store(in: &anyCancellableSet)
        }
        
        // super 的 viewDidLoad 給初始值，所以要在最後 call
        super.viewDidLoad()
    }
    
    // MARK: - Hook methods
    override func getSortingMethod() -> SortingMethod {
        currencySelectionModel.getSortingMethod()
    }
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        currencySelectionModel.set(sortingMethod: sortingMethod, andOrder: sortingOrder)
    }
    
    override func triggerRefreshControl() {
        triggerRefreshControlSubject.send()
    }
}

// MARK: - search bar delegate
extension CurrencySelectionTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText.send("")
    }
}
