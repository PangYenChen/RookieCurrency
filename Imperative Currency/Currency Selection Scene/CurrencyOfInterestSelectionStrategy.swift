import Foundation

final class CurrencyOfInterestSelectionStrategy: CurrencySelectionStrategy {
    // MARK: - initializer
    init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
         completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
        title = R.string.share.currencyOfInterest()
        allowsMultipleSelection = true
        
        self.currencyCodeOfInterest = currencyCodeOfInterest
        self.completionHandler = completionHandler
    }
    
    // MARK: - instance properties
    let title: String
    
    let allowsMultipleSelection: Bool
    
    private var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
}

// MARK: - instance methods
extension CurrencyOfInterestSelectionStrategy {
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.insert(selectedCurrencyCode)
        completionHandler(currencyCodeOfInterest)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.remove(deselectedCurrencyCode)
        completionHandler(currencyCodeOfInterest)
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        currencyCodeOfInterest.contains(currencyCode)
    }
}
