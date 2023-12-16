import Foundation
import Combine

final class CurrencyOfInterestSelectionModel: CurrencySelectionModelProtocol {
    #warning("還沒實作")
    func getSortingMethod() -> SortingMethod {
        fatalError()
    }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        fatalError()
    }
    
    let title: String
    
    private let currencyCodeOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterest.value }
    
    let allowsMultipleSelection: Bool
    
    init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
         selectedCurrencyCodeOfInterest: AnySubscriber<Set<ResponseDataModel.CurrencyCode>, Never>) {
        
        title = R.string.share.currencyOfInterest()
        self.currencyCodeOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(currencyCodeOfInterest)
        allowsMultipleSelection = true
            // initialization completes
        
        self.currencyCodeOfInterest
            .dropFirst()
            .subscribe(selectedCurrencyCodeOfInterest)
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.value.insert(selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.value.remove(deselectedCurrencyCode)
    }
}
