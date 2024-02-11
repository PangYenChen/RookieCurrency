import Foundation

class CurrencySelectionModel: CurrencySelectionModelProtocol {
    // MARK: - initializer
    init(currencySelectionStrategy: CurrencySelectionStrategy,
         supportedCurrencyManager: SupportedCurrencyManager = .shared) {
        self.currencySelectionStrategy = currencySelectionStrategy
        
        self.supportedCurrencyManager = supportedCurrencyManager
        self.currencyCodeDescriptionDictionarySorter = CurrencyCodeDescriptionDictionarySorter(currencyDescriber: supportedCurrencyManager)
        
        self.sortingMethod = .currencyName
        self.initialSortingOrder = .ascending
        self.sortingOrder = initialSortingOrder
        self.searchText = nil
    }
    
    // MARK: - instance properties
    private var sortingMethod: SortingMethod
    
    let initialSortingOrder: SortingOrder
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String?
    
    var resultHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)?
    
    let currencySelectionStrategy: CurrencySelectionStrategy
    
    let supportedCurrencyManager: SupportedCurrencyManager
    
    private let currencyCodeDescriptionDictionarySorter: CurrencyCodeDescriptionDictionarySorter
}

// MARK: - instance methods
extension CurrencySelectionModel {
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
}

private extension CurrencySelectionModel {
    func fetchSupportedCurrency() {
        supportedCurrencyManager.fetchSupportedCurrency { [weak self] result in
            guard let self else { return }
            
            let newResult = result.map { currencyCodeDescriptionDictionary in
                self.currencyCodeDescriptionDictionarySorter.sort(currencyCodeDescriptionDictionary,
                                                                  bySortingMethod: self.sortingMethod,
                                                                  andSortingOrder: self.sortingOrder,
                                                                  thenFilterIfNeedBySearchTextBy: self.searchText)
            }
            
            resultHandler?(newResult)
        }
    }
}
