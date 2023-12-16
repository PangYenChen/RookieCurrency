import Foundation

final class BaseCurrencySelectionModel: CurrencySelectionModelProtocol {
    
    let title: String
    
    private var baseCurrencyCode: String
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode] }
    
    let allowsMultipleSelection: Bool
    
    private var sortingMethod: SortingMethod
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String?
    
    private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
    
    init(baseCurrencyCode: String, completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
        title = R.string.share.baseCurrency()
        self.baseCurrencyCode = baseCurrencyCode
        allowsMultipleSelection = false
        self.completionHandler = completionHandler
        
        sortingMethod = .currencyName
        sortingOrder = .ascending
        searchText = nil
        
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
    }
    
    func getSortingOrder() -> SortingOrder { sortingOrder }
    
    func set(searchText: String?) {
        self.searchText = searchText
    }
    
    func getSearchText() -> String? { self.searchText }
}
