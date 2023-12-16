import Foundation

final class CurrencyOfInterestSelectionModel: CurrencySelectionModelProtocol {
#warning("還沒實作")
    func getSortingOrder() -> SortingOrder {
        fatalError()
    }
    
    func getSortingMethod() -> SortingMethod {
        fatalError()
    }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        fatalError()
    }
    
    let title: String
    
    private var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterest }
    
    let allowsMultipleSelection: Bool
    
    private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
    
    init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
         completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
        title = R.string.share.currencyOfInterest()
        self.currencyCodeOfInterest = currencyCodeOfInterest
        allowsMultipleSelection = true
        self.completionHandler = completionHandler
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.insert(selectedCurrencyCode)
        completionHandler(currencyCodeOfInterest)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.remove(deselectedCurrencyCode)
        completionHandler(currencyCodeOfInterest)
    }
}
