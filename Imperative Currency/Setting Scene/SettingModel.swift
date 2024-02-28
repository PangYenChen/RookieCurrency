import Foundation

final class SettingModel: BaseSettingModel {
    // MARK: - initializer
    init(setting: BaseResultModel.Setting,
         saveCompletionHandler: @escaping SaveHandler,
         cancelCompletionHandler: @escaping CancelHandler,
         currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared) {
        originalNumberOfDays = setting.numberOfDays
        editedNumberOfDays = setting.numberOfDays
        
        originalBaseCurrencyCode = setting.baseCurrencyCode
        editedBaseCurrencyCode = setting.baseCurrencyCode
        
        originalCurrencyCodeOfInterest = setting.currencyCodeOfInterest
        editedCurrencyCodeOfInterest = setting.currencyCodeOfInterest
        
        self.saveCompletionHandler = saveCompletionHandler
        self.cancelCompletionHandler = cancelCompletionHandler
        
        self.currencyDescriber = currencyDescriber
    }
    // MARK: - internal properties
    var editedNumberOfDays: Int
    
    var editedBaseCurrencyCode: ResponseDataModel.CurrencyCode {
        didSet { oldValue != editedBaseCurrencyCode ? editedBaseCurrencyCodeHandler?(editedBaseCurrencyCode) : () }
    }
    var editedBaseCurrencyCodeHandler: BaseCurrencyCodeHandler?
    
    var editedCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    let currencyDescriber: CurrencyDescriberProtocol
    
    var hasChangeToSave: Bool {
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
}

// MARK: - instance methods
extension SettingModel {
    func save() {
        let setting: BaseResultModel.Setting = (numberOfDays: editedNumberOfDays,
                                                baseCurrencyCode: editedBaseCurrencyCode,
                                                currencyCodeOfInterest: editedCurrencyCodeOfInterest)
        saveCompletionHandler(setting)
    }
    
    func cancel() {
        cancelCompletionHandler()
    }
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel {
        let baseCurrencySelectionStrategy: BaseCurrencySelectionStrategy = BaseCurrencySelectionStrategy(
            baseCurrencyCode: editedBaseCurrencyCode
        ) { [unowned self] selectedBaseCurrencyCode in editedBaseCurrencyCode = selectedBaseCurrencyCode }
        
        return CurrencySelectionModel(currencySelectionStrategy: baseCurrencySelectionStrategy)
    }
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel {
        let currencyOfInterestSelectionStrategy: CurrencyOfInterestSelectionStrategy = CurrencyOfInterestSelectionStrategy(
            currencyCodeOfInterest: editedCurrencyCodeOfInterest
        ) { [unowned self] selectedCurrencyCodeOfInterest in editedCurrencyCodeOfInterest = selectedCurrencyCodeOfInterest }
        
        return CurrencySelectionModel(currencySelectionStrategy: currencyOfInterestSelectionStrategy)
    }
}

// MARK: - name space
extension SettingModel {
    typealias SaveHandler = (_ setting: BaseResultModel.Setting) -> Void
    typealias CancelHandler = () -> Void
    
    typealias BaseCurrencyCodeHandler = (_ baseCurrencyCode: ResponseDataModel.CurrencyCode) -> Void
}
