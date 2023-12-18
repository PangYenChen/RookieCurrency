import Foundation
// TODO: protocol 名字要想一下
protocol ImperativeCurrencySelectionModelProtocol: CurrencySelectionModelProtocol {
    var resultHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)? { get set }
}

class CurrencySelectionModel {
    let title: String
    
    let allowsMultipleSelection: Bool
    
    private var sortingMethod: SortingMethod
    
    let initialSortingOrder: SortingOrder
    
    private var sortingOrder: SortingOrder
    
    private var searchText: String?
    
    private(set) var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String]
    
    var resultHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)?

    init(title: String,
         allowsMultipleSelection: Bool) {
        self.title = title
        self.allowsMultipleSelection = allowsMultipleSelection
        
        self.sortingMethod = .currencyName
        self.initialSortingOrder = .ascending
        self.sortingOrder = initialSortingOrder
        self.searchText = nil
        self.currencyCodeDescriptionDictionary = [:]
    }
    
    func getSortingMethod() -> SortingMethod { sortingMethod }
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder) {
        self.sortingMethod = sortingMethod
        self.sortingOrder = sortingOrder
        helper() // TODO: 要改成不重拿
    }
    
    func set(searchText: String?) {
        self.searchText = searchText
        helper() // TODO: 要改成不重拿
    }
    
    func update() {
        helper()
    }
}

private extension CurrencySelectionModel {
    func helper() { // TODO: think a good name
        AppUtility.fetchSupportedSymbols { [weak self] result in
            guard let self else { return }
            if let currencyCodeDescriptionDictionary = try? result.get() {
                self.currencyCodeDescriptionDictionary = currencyCodeDescriptionDictionary
            }
            
            let newResult = result.map { currencyCodeDescriptionDictionary in
                sort(currencyCodeDescriptionDictionary,
                     bySortingMethod: self.sortingMethod,
                     andSortingOrder: self.sortingOrder,
                     thenFilterIfNeedBySearchTextBy: self.searchText)
            }
            
            resultHandler?(newResult)
        }
    }
}

