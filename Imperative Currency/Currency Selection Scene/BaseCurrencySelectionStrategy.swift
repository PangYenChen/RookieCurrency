import Foundation

final class BaseCurrencySelectionStrategy: CurrencySelectionStrategy {
    init(baseCurrencyCode: ResponseDataModel.CurrencyCode,
         completionHandler: @escaping (ResponseDataModel.CurrencyCode) -> Void) {
        title = R.string.share.baseCurrency()
        allowsMultipleSelection = false
        
        self.baseCurrencyCode = baseCurrencyCode
        self.completionHandler = completionHandler
    }
    
    let title: String
    
    let allowsMultipleSelection: Bool
    
    private var baseCurrencyCode: ResponseDataModel.CurrencyCode
    
    private let completionHandler: (ResponseDataModel.CurrencyCode) -> Void
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        baseCurrencyCode = selectedCurrencyCode
        completionHandler(baseCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        // 呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
        // 此時不需回應
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        currencyCode == baseCurrencyCode
    }
}
