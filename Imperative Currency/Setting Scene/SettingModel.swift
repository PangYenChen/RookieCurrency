import Foundation

class SettingModel {
    let originalNumberOfDay: Int
    var editedNumberOfDay: Int
    
    let originalBaseCurrency: ResponseDataModel.CurrencyCode
    var editedBaseCurrency: ResponseDataModel.CurrencyCode
    
    let originalCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    var editedCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var hasChange: Bool {
        originalNumberOfDay != editedNumberOfDay ||
        originalBaseCurrency != editedBaseCurrency ||
        originalCurrencyOfInterest != editedCurrencyOfInterest
    }
    
    let saveCompletionHandler: (Int, ResponseDataModel.CurrencyCode, Set<ResponseDataModel.CurrencyCode>) -> Void
    
    let cancelCompletionHandler: () -> Void
    
    init(numberOfDays: Int,
         baseCurrency: ResponseDataModel.CurrencyCode,
         currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
         saveCompletionHandler: @escaping (Int, ResponseDataModel.CurrencyCode, Set<ResponseDataModel.CurrencyCode>) -> Void,
         cancelCompletionHandler: @escaping () -> Void) {
        originalNumberOfDay = numberOfDays
        editedNumberOfDay = numberOfDays
        
        originalBaseCurrency =  baseCurrency
        editedBaseCurrency =  baseCurrency
        
        originalCurrencyOfInterest = currencyOfInterest
        editedCurrencyOfInterest = currencyOfInterest
        
        self.saveCompletionHandler = saveCompletionHandler
        self.cancelCompletionHandler = cancelCompletionHandler
    }
}
