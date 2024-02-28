import Foundation

final class SettingModel: BaseSettingModel {
    // MARK: - initializer
    init(setting: BaseResultModel.Setting,
         saveCompletionHandler: @escaping SaveHandler,
         cancelCompletionHandler: @escaping CancelHandler,
         currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared) {
        originalNumberOfDays = setting.numberOfDays
        numberOfDays = setting.numberOfDays
        
        originalBaseCurrencyCode = setting.baseCurrencyCode
        baseCurrencyCode = setting.baseCurrencyCode
        
        originalCurrencyCodeOfInterest = setting.currencyCodeOfInterest
        currencyCodeOfInterest = setting.currencyCodeOfInterest
        
        hasModificationsToSave = false
        
        self.saveCompletionHandler = saveCompletionHandler
        self.cancelCompletionHandler = cancelCompletionHandler
        
        self.currencyDescriber = currencyDescriber
    }
    // MARK: - internal properties
    var numberOfDays: Int {
        didSet { updateHasModificationsToSave() }
    }
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode {
        didSet {
            oldValue != baseCurrencyCode ? baseCurrencyCodeDidChangeHandler?() : ()
            updateHasModificationsToSave()
        }
    }
    var baseCurrencyCodeDidChangeHandler: BaseCurrencyCodeDidChangeHandler?
    
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> {
        didSet {
            oldValue != currencyCodeOfInterest ? currencyCodeOfInterestDidChangeHandler?() : ()
            updateHasModificationsToSave()
        }
    }
    var currencyCodeOfInterestDidChangeHandler: CurrencyCodeOfInterestDidChangeHandler?
    
    let currencyDescriber: CurrencyDescriberProtocol
    
    var hasModificationsToSave: Bool {
        didSet { oldValue != hasModificationsToSave ? hasModificationsToSaveHandler?(hasModificationsToSave) : () }
    }
    
    var hasModificationsToSaveHandler: HasModificationsToSaveHandler?
    
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
        let setting: BaseResultModel.Setting = (numberOfDays: numberOfDays,
                                                baseCurrencyCode: baseCurrencyCode,
                                                currencyCodeOfInterest: currencyCodeOfInterest)
        saveCompletionHandler(setting)
    }
    
    func cancel() {
        cancelCompletionHandler()
    }
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel {
        let baseCurrencySelectionStrategy: BaseCurrencySelectionStrategy = BaseCurrencySelectionStrategy(
            baseCurrencyCode: baseCurrencyCode
        ) { [unowned self] selectedBaseCurrencyCode in baseCurrencyCode = selectedBaseCurrencyCode }
        
        return CurrencySelectionModel(currencySelectionStrategy: baseCurrencySelectionStrategy)
    }
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel {
        let currencyOfInterestSelectionStrategy: CurrencyOfInterestSelectionStrategy = CurrencyOfInterestSelectionStrategy(
            currencyCodeOfInterest: currencyCodeOfInterest
        ) { [unowned self] selectedCurrencyCodeOfInterest in currencyCodeOfInterest = selectedCurrencyCodeOfInterest }
        
        return CurrencySelectionModel(currencySelectionStrategy: currencyOfInterestSelectionStrategy)
    }
}

// MARK: - name space
extension SettingModel {
    typealias SaveHandler = (_ setting: BaseResultModel.Setting) -> Void
    typealias CancelHandler = () -> Void
    
    typealias BaseCurrencyCodeDidChangeHandler = () -> Void
    typealias CurrencyCodeOfInterestDidChangeHandler = () -> Void
    typealias HasModificationsToSaveHandler = (_ hasModificationsToSave: Bool) -> Void
}

// MARK: - private method
private extension SettingModel {
    func updateHasModificationsToSave() {
        let isNumberOfDaysModified: Bool = originalNumberOfDays != numberOfDays
        let isBaseCurrencyCodeModified: Bool = originalBaseCurrencyCode != baseCurrencyCode
        let isCurrencyCodeOfInterestModified: Bool = originalCurrencyCodeOfInterest != currencyCodeOfInterest
        
        hasModificationsToSave = isNumberOfDaysModified || isBaseCurrencyCodeModified || isCurrencyCodeOfInterestModified
    }
}
