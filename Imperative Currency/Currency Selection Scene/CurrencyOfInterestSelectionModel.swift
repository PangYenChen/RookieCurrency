import Foundation

final class CurrencyOfInterestSelectionModel: CurrencySelectionModel, ImperativeCurrencySelectionModelProtocol {
    private var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterest }
    
    private let completionHandler: (Set<ResponseDataModel.CurrencyCode>) -> Void
    
    init(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
         completionHandler: @escaping (Set<ResponseDataModel.CurrencyCode>) -> Void) {
        self.currencyCodeOfInterest = currencyCodeOfInterest
        self.completionHandler = completionHandler
        
        super.init(title: R.string.share.currencyOfInterest(),
                   allowsMultipleSelection: true)
    }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.insert(selectedCurrencyCode)
        completionHandler(currencyCodeOfInterest)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencyCodeOfInterest.remove(deselectedCurrencyCode)
        completionHandler(currencyCodeOfInterest)
    }
}
