import Foundation
import Combine

final class CurrencyOfInterestSelectionModel: ReactiveCurrencySelectionModel {
    var state: AnyPublisher<Result<[ResponseDataModel.CurrencyCode: String], Error>, Never>
    
#warning("還沒實作")
    func fetch() {
        fatalError()
    }
    
    func set(searchText: String?) {
        fatalError()
    }
    
    func getSearchText() -> String? {
        fatalError()
    }
    
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
    
    private let currencyCodeOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterest.value }
    
    let allowsMultipleSelection: Bool
    
    init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
         selectedCurrencyCodeOfInterest: AnySubscriber<Set<ResponseDataModel.CurrencyCode>, Never>) {
        
        title = R.string.share.currencyOfInterest()
        self.currencyCodeOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(currencyCodeOfInterest)
        allowsMultipleSelection = true
        state = Empty().eraseToAnyPublisher()
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
