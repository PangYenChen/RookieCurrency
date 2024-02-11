import Foundation
import Combine

final class CurrencyOfInterestSelectionStrategy: CurrencySelectionStrategy {
    // MARK: - initializer
    init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
         selectedCurrencyCodeOfInterest: AnySubscriber<Set<ResponseDataModel.CurrencyCode>, Never>) {
        title = R.string.share.currencyOfInterest()
        allowsMultipleSelection = true
        
        self.currencyCodeOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(currencyCodeOfInterest)
        
        // initialization completes
        self.currencyCodeOfInterest
            .dropFirst()
            .subscribe(selectedCurrencyCodeOfInterest)
    }
    
    let title: String
    
    let allowsMultipleSelection: Bool
    
    private let currencyCodeOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.value.insert(selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.value.remove(deselectedCurrencyCode)
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        currencyCodeOfInterest.value.contains(currencyCode)
    }
}
