import Foundation

final class BaseCurrencySelectionModel: CurrencySelectionModel, ImperativeCurrencySelectionModelProtocol {
    private var baseCurrencyCode: ResponseDataModel.CurrencyCode
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode] }
    
    let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
    
    init(baseCurrencyCode: ResponseDataModel.CurrencyCode,
         completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
        self.baseCurrencyCode = baseCurrencyCode
        self.completionHandler = completionHandler
        
        super.init(title: R.string.share.baseCurrency(),
                   allowsMultipleSelection: false)
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        baseCurrencyCode = selectedCurrencyCode
        completionHandler(baseCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        // 呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
        // 此時不需回應
    }
}
