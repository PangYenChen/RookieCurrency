import Foundation
import Combine

final class BaseCurrencySelectionModel: CurrencySelectionModel, ReactiveCurrencySelectionModel {
    private let baseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    private var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { [baseCurrencyCode.value] }
    
    init(baseCurrencyCode: String,
         selectedBaseCurrencyCode: AnySubscriber<ResponseDataModel.CurrencyCode, Never>) {
        self.baseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(baseCurrencyCode)
        
        super.init(title: R.string.share.baseCurrency(),
                   allowsMultipleSelection: false)
        
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
