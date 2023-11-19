import Foundation

class SettingModel: BaseSettingModel {
    private let originalNumberOfDay: Int
    var editedNumberOfDay: Int
    
    private let originalBaseCurrency: ResponseDataModel.CurrencyCode
    var editedBaseCurrency: ResponseDataModel.CurrencyCode
    
    private let originalCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
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
    
    override func save() {
        saveCompletionHandler(editedNumberOfDay, editedBaseCurrency, editedCurrencyOfInterest)
    }
    
    override func cancel() {
        cancelCompletionHandler()
    }
}
