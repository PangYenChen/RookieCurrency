import Foundation
import Combine

class CurrencySelectionModel: CurrencySelectionModelProtocol {
    // MARK: - initializer
    init(
        currencySelectionStrategy: CurrencySelectionStrategy,
        supportedCurrencyManager: SupportedCurrencyManager = .shared
    ) {
        self.currencySelectionStrategy = currencySelectionStrategy
        
        self.supportedCurrencyManager = supportedCurrencyManager
        
        initialSortingOrder = .ascending
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        searchText = CurrentValueSubject<String?, Never>(nil)
        
        fetchSubject = PassthroughSubject<Void, Never>()
        
        let currencyCodeDescriptionDictionarySorter: CurrencyCodeDescriptionDictionarySorter = CurrencyCodeDescriptionDictionarySorter(
            currencyDescriber: supportedCurrencyManager
        )
        
        result = fetchSubject
            .flatMap { supportedCurrencyManager.supportedCurrency().convertOutputToResult() }
            .combineLatest(sortingMethodAndOrder, searchText) { result, sortingMethodAndOrder, searchText in
                result.map { currencyCodeDescriptionDictionary in
                    currencyCodeDescriptionDictionarySorter.sort(currencyCodeDescriptionDictionary,
                                                                 bySortingMethod: sortingMethodAndOrder.method,
                                                                 andSortingOrder: sortingMethodAndOrder.order,
                                                                 thenFilterIfNeedBySearchTextBy: searchText)
                }
            }
            .eraseToAnyPublisher()
    }
    
    var initialSortingOrder: SortingOrder
    
    var result: AnyPublisher<Result<[ResponseDataModel.CurrencyCode], Error>, Never>
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    private let searchText: CurrentValueSubject<String?, Never>
    
    private let fetchSubject: PassthroughSubject<Void, Never>
    
    let currencySelectionStrategy: CurrencySelectionStrategy
    
    let supportedCurrencyManager: SupportedCurrencyManager
}

// MARK: - other methods
extension CurrencySelectionModel {
    func getSortingMethod() -> SortingMethod { sortingMethodAndOrder.value.method }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        sortingMethodAndOrder.send((method: sortingMethod, order: sortingOrder))
    }
    
    func set(searchText: String?) { self.searchText.send(searchText) }
    
    func refresh() { fetchSubject.send() }
}
