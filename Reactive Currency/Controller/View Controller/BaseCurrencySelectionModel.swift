import Foundation
import Combine

final class BaseCurrencySelectionModel: CurrencySelectionModelProtocol {
    let title: String
    
    private let baseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode.value] }
    
    let allowsMultipleSelection: Bool
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    init(baseCurrencyCode: String,
         selectedBaseCurrencyCode: AnySubscriber<ResponseDataModel.CurrencyCode, Never>) {
        
        title = R.string.share.baseCurrency()
        self.baseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(baseCurrencyCode)
        allowsMultipleSelection = false
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        // initialization completes
        
        self.baseCurrencyCode
            .dropFirst()
            .subscribe(selectedBaseCurrencyCode)
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        baseCurrencyCode.send(selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
    // allowsMultipleSelection = false，會呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
    }
    
    func getSortingMethod() -> SortingMethod { sortingMethodAndOrder.value.method }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        sortingMethodAndOrder.send((method: sortingMethod, order: sortingOrder))
    }
    
    func getSortingOrder() -> SortingOrder { sortingMethodAndOrder.value.order }
}
