import Foundation
import Combine
// TODO: protocol 名字要想一下
protocol ReactiveCurrencySelectionModel: CurrencySelectionModelProtocol {
    var result: AnyPublisher<Result<[ResponseDataModel.CurrencyCode], Error>, Never> { get }
}

class CurrencySelectionModel {
    let title: String
    
    let allowsMultipleSelection: Bool
    
    var initialSortingOrder: SortingOrder
    
    var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]
    
    var result: AnyPublisher<Result<[ResponseDataModel.CurrencyCode], Error>, Never>
    
    private let sortingMethodAndOrder: CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>
    
    private let searchText: CurrentValueSubject<String?, Never>
    
    private let fetchSubject: PassthroughSubject<Void, Never>
    
    init(title: String, allowsMultipleSelection: Bool) {
        
        self.title = title
        self.allowsMultipleSelection = allowsMultipleSelection
        
        initialSortingOrder = .ascending
        sortingMethodAndOrder = CurrentValueSubject<(method: SortingMethod, order: SortingOrder), Never>((method: .currencyName, order: .ascending))
        searchText = CurrentValueSubject<String?, Never>(nil)
        
        fetchSubject = PassthroughSubject<Void, Never>()
        
        currencyCodeDescriptionDictionary = [:]
        
        result = fetchSubject
            .flatMap { AppUtility.supportedSymbolsPublisher().convertOutputToResult() }
            .combineLatest(sortingMethodAndOrder, searchText)
            .map { result, sortingMethodAndOrder, searchText in
                result.map { currencyCodeDescriptionDictionary in
                    Self.sort(currencyCodeDescriptionDictionary,
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
}
