import Foundation

final class BaseCurrencySelectionModel: ImperativeCurrencySelectionModelProtocol {
    var stateHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)?
    
    let title: String
    
    private var baseCurrencyCode: String
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode] }
    
    let allowsMultipleSelection: Bool
    
    private var sortingMethod: SortingMethod
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String?
    
    private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
    
    var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]
    
    let initialSortingOrder: SortingOrder
    
    init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
        title = R.string.share.baseCurrency()
        self.baseCurrencyCode = baseCurrencyCode
        allowsMultipleSelection = false
        self.completionHandler = completionHandler
        
        sortingMethod = .currencyName
        sortingOrder = .ascending
        searchText = nil
        currencyCodeDescriptionDictionary = [:]
        initialSortingOrder = .ascending
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        completionHandler(selectedCurrencyCode)
        baseCurrencyCode = selectedCurrencyCode
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
            // allowsMultipleSelection = false，會呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
    }
    
    func getSortingMethod() -> SortingMethod { sortingMethod }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        helper() // TODO: 要改成不重拿
    }
    
    func getSortingOrder() -> SortingOrder { sortingOrder }
    
    func set(searchText: String?) {
        self.searchText = searchText
        helper() // TODO: 要改成不重拿
    }
    
    func getSearchText() -> String? { searchText }
    
    func fetch() {
        helper()
    }
}

private extension BaseCurrencySelectionModel {
    func helper() {
        AppUtility.fetchSupportedSymbols { [weak self] result in
            guard let self else { return }
            if let currencyCodeDescriptionDictionary = try? result.get() {
                self.currencyCodeDescriptionDictionary = currencyCodeDescriptionDictionary
            }
            
            let newResult = result.map { currencyCodeDescriptionDictionary in
                Self.convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
                                                      sortingMethod: self.getSortingMethod(),
                                                      sortingOrder: self.getSortingOrder(),
                                                      searchText: self.getSearchText())
            }
            
            stateHandler?(newResult)
        }
    }
}
