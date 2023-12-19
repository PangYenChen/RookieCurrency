import Foundation
import Combine

final class BaseCurrencySelectionStrategy: CurrencySelectionStrategy {
    let title: String
    
    let allowsMultipleSelection: Bool
    
    private let baseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    init(baseCurrencyCode: String,
         selectedBaseCurrencyCode: AnySubscriber<ResponseDataModel.CurrencyCode, Never>) {
        title = R.string.share.baseCurrency()
        allowsMultipleSelection = false
        
        self.baseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(baseCurrencyCode)
        
        // initialization completes
        self.baseCurrencyCode
            .dropFirst()
            .subscribe(selectedBaseCurrencyCode)
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        baseCurrencyCode.send(selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        // 呼叫這個 delegate method 的唯一時機是其他 cell 被選取了，table view deselect 原本被選取的 cell
        // 此時不需回應
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        baseCurrencyCode.value == currencyCode
    }
}
