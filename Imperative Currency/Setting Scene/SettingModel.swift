import Foundation

class SettingModel {
    // MARK: - internal properties
    var editedNumberOfDays: Int
    
    var editedBaseCurrencyCode: ResponseDataModel.CurrencyCode
    
    var editedCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var hasChange: Bool {
        originalNumberOfDays != editedNumberOfDays ||
        originalBaseCurrencyCode != editedBaseCurrencyCode ||
        originalCurrencyCodeOfInterest != editedCurrencyCodeOfInterest
    }
    
    // MARK: - private properties
    private let originalNumberOfDays: Int
    
    private let originalBaseCurrencyCode: ResponseDataModel.CurrencyCode
    
    private let originalCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    private let saveCompletionHandler: SaveHandler
    
    private let cancelCompletionHandler: CancelHandler
    
    init(setting: BaseResultModel.Setting,
         saveCompletionHandler: @escaping SaveHandler,
         cancelCompletionHandler: @escaping CancelHandler) {
        originalNumberOfDays = setting.numberOfDays
        editedNumberOfDays = setting.numberOfDays
        
        originalBaseCurrencyCode = setting.baseCurrencyCode
        editedBaseCurrencyCode = setting.baseCurrencyCode
        
        originalCurrencyCodeOfInterest = setting.currencyCodeOfInterest
        editedCurrencyCodeOfInterest = setting.currencyCodeOfInterest
        
        self.saveCompletionHandler = saveCompletionHandler
        self.cancelCompletionHandler = cancelCompletionHandler
    }
}

// MARK: - Confirming BaseSettingModel
extension SettingModel: BaseSettingModel {
    func save() {
        let setting = (numberOfDays: editedNumberOfDays,
                       baseCurrencyCode: editedBaseCurrencyCode,
                       currencyCodeOfInterest: editedCurrencyCodeOfInterest)
        saveCompletionHandler(setting)
    }
    
    func cancel() {
        cancelCompletionHandler()
    }
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel {
        let baseCurrencySelectionStrategy = BaseCurrencySelectionStrategy(
            baseCurrencyCode: editedBaseCurrencyCode
        ) { [unowned self] selectedBaseCurrencyCode in
            editedBaseCurrencyCode = selectedBaseCurrencyCode
        }
        
        return CurrencySelectionModel(currencySelectionStrategy: baseCurrencySelectionStrategy)
    }
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel {
        let currencyOfInterestSelectionStrategy = CurrencyOfInterestSelectionStrategy(
            currencyCodeOfInterest: editedCurrencyCodeOfInterest
        ) { [unowned self] selectedCurrencyCodeOfInterest in
            editedCurrencyCodeOfInterest = selectedCurrencyCodeOfInterest
        }
        
        return CurrencySelectionModel(currencySelectionStrategy: currencyOfInterestSelectionStrategy)
    }
    
}

// MARK: - name space
extension SettingModel {
    typealias SaveHandler = (_ setting: BaseResultModel.Setting) -> Void
    typealias CancelHandler = () -> Void
}
