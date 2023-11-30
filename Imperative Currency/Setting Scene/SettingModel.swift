import Foundation

class SettingModel: BaseSettingModel {
    // MARK: - internal properties
    var editedNumberOfDays: Int
    
    var editedBaseCurrencyCode: ResponseDataModel.CurrencyCode
    
    var editedCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var hasChange: Bool {
        originalNumberOfDays != editedNumberOfDays ||
        originalBaseCurrencyCode != editedBaseCurrencyCode ||
        originalCurrencyOfInterest != editedCurrencyOfInterest
    }
    
    // MARK: - private properties
    private let originalNumberOfDays: Int
    
    private let originalBaseCurrencyCode: ResponseDataModel.CurrencyCode
    
    private let originalCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    private let saveCompletionHandler: SaveHandler
    
    private let cancelCompletionHandler: CancelHandler
    
    init(userSetting: BaseResultModel.UserSetting,
         saveCompletionHandler: @escaping SaveHandler,
         cancelCompletionHandler: @escaping CancelHandler) {
        originalNumberOfDays = userSetting.numberOfDays
        editedNumberOfDays = userSetting.numberOfDays
        
        originalBaseCurrencyCode = userSetting.baseCurrencyCode
        editedBaseCurrencyCode = userSetting.baseCurrencyCode
        
        originalCurrencyOfInterest = userSetting.currencyOfInterest
        editedCurrencyOfInterest = userSetting.currencyOfInterest
        
        self.saveCompletionHandler = saveCompletionHandler
        self.cancelCompletionHandler = cancelCompletionHandler
    }
    
    override func save() {
        let userSetting = (numberOfDays: editedNumberOfDays,
                           baseCurrencyCode: editedBaseCurrencyCode,
                           currencyOfInterest: editedCurrencyOfInterest)
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
