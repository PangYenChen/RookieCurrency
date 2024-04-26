import Foundation

/// 這裡的 base 是 base class 的意思，不是基準貨幣
protocol BaseCurrencySelectionModelProtocol: CurrencyDescriberProxy {
    var title: String { get }
    
    var allowsMultipleSelection: Bool { get }
    
    var initialSortingOrder: CurrencySelectionModel.SortingOrder { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool
    
    func getSortingMethod() -> CurrencySelectionModel.SortingMethod
    
    func set( // TODO: 考慮拿掉
        sortingMethod: CurrencySelectionModel.SortingMethod,
        andOrder sortingOrder: CurrencySelectionModel.SortingOrder
    )
    
    func set(searchText: String?) // TODO: 考慮拿掉
    
    func refresh()
}
