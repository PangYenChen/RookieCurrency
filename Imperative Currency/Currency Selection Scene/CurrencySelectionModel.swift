import Foundation

class CurrencySelectionModel: CurrencySelectionModelProtocol {
    let title: String
    
    let allowsMultipleSelection: Bool
    
    private var sortingMethod: SortingMethod
    
    let initialSortingOrder: SortingOrder
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String?
    
    var resultHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)?
    
    private let currencySelectionStrategy: CurrencySelectionStrategy
    
    let supportedCurrencyManager: SupportedCurrencyManager

    init(currencySelectionStrategy: CurrencySelectionStrategy,
         supportedCurrencyManager: SupportedCurrencyManager = .shared) {
        self.title = currencySelectionStrategy.title
        self.allowsMultipleSelection = currencySelectionStrategy.allowsMultipleSelection
        self.currencySelectionStrategy = currencySelectionStrategy
        
        self.supportedCurrencyManager = supportedCurrencyManager
        
        self.sortingMethod = .currencyName
        self.initialSortingOrder = .ascending
        self.sortingOrder = initialSortingOrder
        self.searchText = nil
    }
    
    func getSortingMethod() -> SortingMethod { sortingMethod }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        fetchSupportedCurrency()
    }
    
    func set(searchText: String?) {
        self.searchText = searchText
        fetchSupportedCurrency()
    }
    
    func update() {
        fetchSupportedCurrency()
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.select(currencyCode: selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.deselect(currencyCode: deselectedCurrencyCode)
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        currencySelectionStrategy.isCurrencyCodeSelected(currencyCode)
    }
}

private extension CurrencySelectionModel {
    func fetchSupportedCurrency() {
        supportedCurrencyManager.fetchSupportedCurrency { [weak self] result in
            guard let self else { return }
            
            let newResult = result.map { currencyCodeDescriptionDictionary in
                Self.sort(currencyCodeDescriptionDictionary,
                          bySortingMethod: self.sortingMethod,
                          andSortingOrder: self.sortingOrder,
                          thenFilterIfNeedBySearchTextBy: self.searchText)
            }
            
            resultHandler?(newResult)
        }
    }
}

extension CurrencySelectionModel: SupportedCurrencyManagerHolder {}
