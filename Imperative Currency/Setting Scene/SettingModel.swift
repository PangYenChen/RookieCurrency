import Foundation

class SettingModel: BaseSettingModel {
    // MARK: - internal properties
    var editedNumberOfDays: Int
    
    var editedBaseCurrency: ResponseDataModel.CurrencyCode
    
    var editedCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var hasChange: Bool {
        originalNumberOfDays != editedNumberOfDays ||
        originalBaseCurrency != editedBaseCurrency ||
        originalCurrencyOfInterest != editedCurrencyOfInterest
    }
    
    // MARK: - private properties
    private let originalNumberOfDays: Int
    
    private let originalBaseCurrency: ResponseDataModel.CurrencyCode
    
    private let originalCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    private let saveCompletionHandler: SaveHandler
    
    private let cancelCompletionHandler: CancelHandler
    
    init(userSetting: BaseResultModel.UserSetting,
         saveCompletionHandler: @escaping SaveHandler,
         cancelCompletionHandler: @escaping CancelHandler) {
        originalNumberOfDays = userSetting.numberOfDays
        editedNumberOfDays = userSetting.numberOfDays
        
        originalBaseCurrency = userSetting.baseCurrency
        editedBaseCurrency = userSetting.baseCurrency
        
        originalCurrencyOfInterest = userSetting.currencyOfInterest
        editedCurrencyOfInterest = userSetting.currencyOfInterest
        
        self.saveCompletionHandler = saveCompletionHandler
        self.cancelCompletionHandler = cancelCompletionHandler
    }
    
    override func save() {
        let userSetting = (numberOfDays: editedNumberOfDays, baseCurrency: editedBaseCurrency, currencyOfInterest: editedCurrencyOfInterest)
        saveCompletionHandler(userSetting)
    }
    
    override func cancel() {
        cancelCompletionHandler()
    }
}

// MARK: - name space
extension SettingModel {
    typealias SaveHandler = (_ userSetting: BaseResultModel.UserSetting) -> Void
    typealias CancelHandler = () -> Void
}
