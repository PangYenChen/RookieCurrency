import UIKit
import Combine

final class CurrencyTableViewController: BaseCurrencySelectionTableViewController {
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    private let searchText: CurrentValueSubject<String, Never>
    
    private let triggerRefreshControlSubject: PassthroughSubject<Void, Never>
    
    // TODO: 看這個能不能用 publisher 之類的取代
    private var isFirstTimePopulate: Bool
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - life cycle
    required init?(coder: NSCoder, strategy: CurrencyTableStrategy) {
        
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        
        searchText = CurrentValueSubject<String, Never>("")
        
        triggerRefreshControlSubject = PassthroughSubject<Void, Never>()
        
        isFirstTimePopulate = true
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, strategy: strategy)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {

        // subscribe
        do {
            sortingMethodAndOrder
                .sink { [unowned self] (sortingMethod, sortingOrder) in
                    sortBarButtonItem.menu?.children.first?.subtitle = R.string.currencyScene.sortingWay(sortingMethod.localizedName, sortingOrder.localizedName)
                }
                .store(in: &anyCancellableSet)
            
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
            
            symbolsResult.resultSuccess()
                .combineLatest(sortingMethodAndOrder, searchText)
                .sink { [unowned self] (supportedSymbols, sortingMethodAndOrder, searchText) in
                    currencyCodeDescriptionDictionary = supportedSymbols
                    
                    let (sortingMethod, sortingOrder) = sortingMethodAndOrder
                    
                    convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: supportedSymbols,
                                                     sortingMethod: sortingMethod,
                                                     sortingOrder: sortingOrder,
                                                     searchText: searchText,
                                                     isFirstTimePopulate: isFirstTimePopulate)
                    isFirstTimePopulate = false
                }
                .store(in: &anyCancellableSet)
        }
        
        // super 的 viewDidLoad 給初始值，所以要在最後 call
        super.viewDidLoad()
    }
    
    // MARK: - Hook methods
    override func getSortingMethod() -> BaseCurrencySelectionTableViewController.SortingMethod {
        sortingMethodAndOrder.value.method
    }
    
    override func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        sortingMethodAndOrder.send((method: sortingMethod, order: sortingOrder))
    }
    
    override func triggerRefreshControl() {
        triggerRefreshControlSubject.send()
    }
}

// MARK: - search bar delegate
extension CurrencyTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText.send("")
    }
}

// MARK: - strategy
extension CurrencyTableViewController {
    
    final class BaseCurrencySelectionStrategy: CurrencyTableStrategy {
        
        let title: String
        
        private let baseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
        
        var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode.value] }
        
        let allowsMultipleSelection: Bool
        
        init(baseCurrencyCode: String,
             selectedBaseCurrencyCode: AnySubscriber<ResponseDataModel.CurrencyCode, Never>) {
            
            title = R.string.share.baseCurrency()
            self.baseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(baseCurrencyCode)
            allowsMultipleSelection = false
            // initialization completes
            
            self.baseCurrencyCode
                .dropFirst()
                .subscribe(selectedBaseCurrencyCode)
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            baseCurrencyCode.send(selectedCurrencyCode)
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            // allowsMultipleSelection = false，會呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
        }
    }
    
    final class CurrencyOfInterestSelectionStrategy: CurrencyTableStrategy {

        let title: String
        
        private let currencyCodeOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>

        var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterest.value }
        
        let allowsMultipleSelection: Bool

        init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
             selectedCurrencyCodeOfInterest: AnySubscriber<Set<ResponseDataModel.CurrencyCode>, Never>) {
            
            title = R.string.share.currencyOfInterest()
            self.currencyCodeOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(currencyCodeOfInterest)
            allowsMultipleSelection = true
            // initialization completes
            
            self.currencyCodeOfInterest
                .dropFirst()
                .subscribe(selectedCurrencyCodeOfInterest)
        }
        
        func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyCodeOfInterest.value.insert(selectedCurrencyCode)
        }
        
        func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            currencyCodeOfInterest.value.remove(deselectedCurrencyCode)
        }
    }
}
