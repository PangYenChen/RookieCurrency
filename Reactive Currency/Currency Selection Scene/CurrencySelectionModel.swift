import Foundation
import Combine

class CurrencySelectionModel: CurrencySelectionModelProtocol {
    let title: String
    
    let allowsMultipleSelection: Bool
    
    var initialSortingOrder: SortingOrder
    
    var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]
    
    var result: AnyPublisher<Result<[ResponseDataModel.CurrencyCode], Error>, Never>
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    private let searchText: CurrentValueSubject<String?, Never>
    
    private let fetchSubject: PassthroughSubject<Void, Never>
    
    private let currencySelectionStrategy: CurrencySelectionStrategy
    
    let supportedCurrencyManager: SupportedCurrencyManager
    
    var currencyDescriber: CurrencyDescriber { supportedCurrencyManager }
    
    init(currencySelectionStrategy: CurrencySelectionStrategy,
         supportedCurrencyManager: SupportedCurrencyManager = .shared,
         currencyCodeDescriptionDictionarySorter: CurrencyCodeDescriptionDictionarySorter = .shared) {
        
        self.title = currencySelectionStrategy.title
        self.allowsMultipleSelection = currencySelectionStrategy.allowsMultipleSelection
        self.currencySelectionStrategy = currencySelectionStrategy
        
        self.supportedCurrencyManager = supportedCurrencyManager
        
        initialSortingOrder = .ascending
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        searchText = CurrentValueSubject<String?, Never>(nil)
        
        fetchSubject = PassthroughSubject<Void, Never>()
        
        currencyCodeDescriptionDictionary = [:]
        
        result = fetchSubject
            .flatMap { supportedCurrencyManager.supportedCurrency().convertOutputToResult() }
            .combineLatest(sortingMethodAndOrder, searchText)
            .map { result, sortingMethodAndOrder, searchText in
                result.map { currencyCodeDescriptionDictionary in
                    currencyCodeDescriptionDictionarySorter.sort(currencyCodeDescriptionDictionary,
                                                                 bySortingMethod: sortingMethodAndOrder.method,
                                                                 andSortingOrder: sortingMethodAndOrder.order,
                                                                 thenFilterIfNeedBySearchTextBy: searchText)
                }
            }
            .eraseToAnyPublisher()
        
    }
    
    func getSortingMethod() -> SortingMethod { sortingMethodAndOrder.value.method }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        sortingMethodAndOrder.send((method: sortingMethod, order: sortingOrder))
    }
    
    func set(searchText: String?) { self.searchText.send(searchText) }
    
    func update() { fetchSubject.send() }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.select(currencyCode: selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.deselect(currencyCode: deselectedCurrencyCode)
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        currencySelectionStrategy.isCurrencyCodeSelected(currencyCode)
    }
}
