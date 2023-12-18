import Foundation
import Combine

final class BaseCurrencySelectionModel: ReactiveCurrencySelectionModel {
    var initialSortingOrder: SortingOrder
    
    var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]
    
    var state: AnyPublisher<Result<[ResponseDataModel.CurrencyCode], Error>, Never>
    
    let title: String
    
    private let baseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode.value] }
    
    let allowsMultipleSelection: Bool
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    private let searchText: CurrentValueSubject<String?, Never>
    
    private let fetchSubject: PassthroughSubject<Void, Never>
    
    init(baseCurrencyCode: String,
         selectedBaseCurrencyCode: AnySubscriber<ResponseDataModel.CurrencyCode, Never>) {
        
        title = R.string.share.baseCurrency()
        self.baseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(baseCurrencyCode)
        allowsMultipleSelection = false
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        
        searchText = CurrentValueSubject<String?, Never>(nil)
        
        fetchSubject = PassthroughSubject<Void, Never>()
        
        initialSortingOrder = .ascending
        
        state = fetchSubject
            .flatMap { AppUtility.supportedSymbolsPublisher().convertOutputToResult() }
            .combineLatest(sortingMethodAndOrder, searchText)
            .map { result, sortingMethodAndOrder, searchText in
                
                result.map { dictionary in
                    BaseCurrencySelectionModel.convertDataThenPopulateTableView(
                        currencyCodeDescriptionDictionary: dictionary,
                        sortingMethod: sortingMethodAndOrder.method,
                        sortingOrder: sortingMethodAndOrder.order,
                        searchText: searchText
                    )
                }
            }
            .eraseToAnyPublisher()
        
        currencyCodeDescriptionDictionary = [:]
        
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
    
    func set(searchText: String?) { self.searchText.send(searchText) }
    
    func getSearchText() -> String? { searchText.value }
    
    func fetch() { fetchSubject.send() }
}
