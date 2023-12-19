import Foundation

class CurrencySelectionModel: CurrencySelectionModelProtocol {
    let title: String
    
    let allowsMultipleSelection: Bool
    
    private var sortingMethod: SortingMethod
    
    let initialSortingOrder: SortingOrder
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String?
    
    private(set) var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]
    
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
        self.currencyCodeDescriptionDictionary = [:]
    }
    
    func getSortingMethod() -> SortingMethod { sortingMethod }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        helper() // TODO: 要改成不重拿
    }
    
    func set(searchText: String?) {
        self.searchText = searchText
        helper() // TODO: 要改成不重拿
    }
    
    func update() {
        helper()
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
    func helper() { // TODO: think a good name
        supportedCurrencyManager.fetchSupportedCurrency { [weak self] result in
            guard let self else { return }
            if let currencyCodeDescriptionDictionary = try? result.get() {
                self.currencyCodeDescriptionDictionary = currencyCodeDescriptionDictionary
            }
            
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
