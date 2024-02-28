import Foundation
import Combine

class SettingModel {
    // MARK: - initializer
    init(setting: BaseResultModel.Setting,
         saveSettingSubscriber: AnySubscriber<BaseResultModel.Setting, Never>,
         cancelSubscriber: AnySubscriber<Void, Never>,
         currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared) {
        self.currencyDescriber = currencyDescriber
        
        do {
            editedNumberOfDaysSubject = CurrentValueSubject<Int, Never>(setting.numberOfDays)
            editedNumberOfDaysPublisher = editedNumberOfDaysSubject.eraseToAnyPublisher()
        }
        
        editedBaseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(setting.baseCurrencyCode)
        
        editedCurrencyCodeOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(setting.currencyCodeOfInterest)
        
        // has changes
        do {
            let numberOfDaysHasChanges = editedNumberOfDaysPublisher.map { $0 != setting.numberOfDays }
            let baseCurrencyCodeHasChanges = editedBaseCurrencyCode.map { $0 != setting.baseCurrencyCode }
            let currencyCodeOfInterestHasChanges = editedCurrencyCodeOfInterest.map { $0 != setting.currencyCodeOfInterest }
            hasChangesToSave = Publishers.CombineLatest3(numberOfDaysHasChanges, baseCurrencyCodeHasChanges, currencyCodeOfInterestHasChanges)
                .map { $0 || $1 || $2 }
                .eraseToAnyPublisher()
        }
        
        cancelSubject = PassthroughSubject<Void, Never>()
        
        saveSubject = PassthroughSubject<Void, Never>()
        
        // finish initialization
        saveSubject
            .withLatestFrom(editedNumberOfDaysPublisher)
            .map { $1 }
            .withLatestFrom(editedBaseCurrencyCode)
            .withLatestFrom(editedCurrencyCodeOfInterest)
            .map { (numberOfDays: $0.0, baseCurrencyCode: $0.1, currencyCodeOfInterest: $1) }
            .subscribe(saveSettingSubscriber)
        
        cancelSubject
            .subscribe(cancelSubscriber)
    }
    
    // MARK: - properties
    
    private let editedNumberOfDaysSubject: CurrentValueSubject<Int, Never>
    
    let editedNumberOfDaysPublisher: AnyPublisher<Int, Never>
    
    let editedBaseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    let editedCurrencyCodeOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    let hasChangesToSave: AnyPublisher<Bool, Never>
    
    let currencyDescriber: CurrencyDescriberProtocol
    
    // MARK: - properties used to communicate with `ResultModel`
    private let cancelSubject: PassthroughSubject<Void, Never>
    
    private let saveSubject: PassthroughSubject<Void, Never>
}

// MARK: - Confirming BaseSettingModel
extension SettingModel: BaseSettingModel {
    var editedNumberOfDays: Int { editedNumberOfDaysSubject.value }
    
    func cancel() {
        cancelSubject.send()
    }
    
    func save() {
        saveSubject.send()
    }
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel {
        let baseCurrencySelectionStrategy: BaseCurrencySelectionStrategy = BaseCurrencySelectionStrategy(
            baseCurrencyCode: editedBaseCurrencyCode.value,
            selectedBaseCurrencyCode: AnySubscriber(editedBaseCurrencyCode)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: baseCurrencySelectionStrategy)
    }
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel {
        let currencyOfInterestSelectionStrategy: CurrencyOfInterestSelectionStrategy = CurrencyOfInterestSelectionStrategy(
            currencyCodeOfInterest: editedCurrencyCodeOfInterest.value,
            selectedCurrencyCodeOfInterest: AnySubscriber(editedCurrencyCodeOfInterest)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: currencyOfInterestSelectionStrategy)
    }
}

extension SettingModel {
    func set(editedNumberOfDays: Int) {
        editedNumberOfDaysSubject.send(editedNumberOfDays)
    }
}
