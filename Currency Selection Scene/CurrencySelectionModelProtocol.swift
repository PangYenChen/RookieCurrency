import Foundation

protocol CurrencySelectionModelProtocol {
    
    var title: String { get }
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { get }
    
    var allowsMultipleSelection: Bool { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func getSortingMethod() -> SortingMethod
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder)
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
