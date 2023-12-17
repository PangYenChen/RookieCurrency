import Foundation

protocol CurrencySelectionModelProtocol {
    
    var title: String { get }
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { get }
    
    var allowsMultipleSelection: Bool { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func getSortingMethod() -> SortingMethod
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder)
    
    @available(*, deprecated, message: "邏輯全部搬到 model 後，要刪掉這個 method")
    func getSortingOrder() -> SortingOrder
    
    func set(searchText: String?)
    
    @available(*, deprecated, message: "邏輯全部搬到 model 後，要刪掉這個 method")
    func getSearchText() -> String?
    
    func fetch()
}

protocol ImperativeCurrencySelectionModelProtocol: CurrencySelectionModelProtocol {
    var stateHandler: ((Result<[ResponseDataModel.CurrencyCode: String], Error>) -> Void)? { get set }
}

    // TODO: 要做出一個 name space
enum SortingMethod {
    case currencyName
    case currencyCode
    case currencyNameZhuyin
    
    var localizedName: String {
        switch self {
        case .currencyName: return R.string.currencyScene.currencyName()
        case .currencyCode: return R.string.currencyScene.currencyCode()
        case .currencyNameZhuyin: return R.string.currencyScene.currencyZhuyin()
        }
    }
}

enum SortingOrder {
    case ascending
    case descending
    
    var localizedName: String {
        switch self {
        case .ascending: return R.string.currencyScene.ascending()
        case .descending: return R.string.currencyScene.descending()
        }
    }
}
