import Foundation
import Combine

final class CurrencyOfInterestSelectionModel: CurrencySelectionModel, ReactiveCurrencySelectionModel {
    private let currencyCodeOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    private var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterest.value }
    
    init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
         selectedCurrencyCodeOfInterest: AnySubscriber<Set<ResponseDataModel.CurrencyCode>, Never>) {
        
        self.currencyCodeOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(currencyCodeOfInterest)
        
        super.init(title: R.string.share.currencyOfInterest(),
                   allowsMultipleSelection: true)
    
        // initialization completes
        self.currencyCodeOfInterest
            .dropFirst()
            .subscribe(selectedCurrencyCodeOfInterest)
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.value.insert(selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.value.remove(deselectedCurrencyCode)
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        selectedCurrencyCode.contains(currencyCode)
    }
}
