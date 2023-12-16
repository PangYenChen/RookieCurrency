import Foundation

protocol CurrencySelectionModelProtocol {
    
    var title: String { get }
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { get }
    
    var allowsMultipleSelection: Bool { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func getSortingMethod() -> SortingMethod
    
    func set(sortingMethod: SortingMethod)
}

enum SortingMethod {
    // TODO: 要做出一個 name space
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
