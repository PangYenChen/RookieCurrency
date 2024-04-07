import Foundation

class CurrencySelectionModel: CurrencySelectionModelProtocol, BaseCurrencySelectionModelProtocol {
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
    
    var sortedCurrencyCodeResultHandler: SortedCurrencyCodeResultHandler?
    
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
    
    func refresh() {
        fetchSupportedCurrency()
    }
}

private extension CurrencySelectionModel {
    func fetchSupportedCurrency() {
        supportedCurrencyManager.getSupportedCurrency { [weak self] result in
            guard let self else { return }
            
            let newResult: Result<[ResponseDataModel.CurrencyCode], Error> = result
                .map { currencyCodeDescriptionDictionary in
                    self.currencyCodeDescriptionDictionarySorter.sort(currencyCodeDescriptionDictionary,
                                                                      bySortingMethod: self.sortingMethod,
                                                                      andSortingOrder: self.sortingOrder,
                                                                      thenFilterIfNeedBySearchTextBy: self.searchText)
                }
            
            sortedCurrencyCodeResultHandler?(newResult)
        }
    }
}

extension CurrencySelectionModel {
    typealias SortedCurrencyCodeResultHandler = (_ sortedCurrencyCodeResult: Result<[ResponseDataModel.CurrencyCode], Error>) -> Void
}
