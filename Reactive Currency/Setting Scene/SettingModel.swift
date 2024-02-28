import Foundation
import Combine

class SettingModel {
    // MARK: - initializer
    init(setting: BaseResultModel.Setting,
         saveSettingSubscriber: AnySubscriber<BaseResultModel.Setting, Never>,
         cancelSubscriber: AnySubscriber<Void, Never>,
         currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared) {
        self.currencyDescriber = currencyDescriber
        
        do /*initialize edited number of days*/ {
            editedNumberOfDaysSubject = CurrentValueSubject<Int, Never>(setting.numberOfDays)
            editedNumberOfDaysPublisher = editedNumberOfDaysSubject.eraseToAnyPublisher()
        }
        
        do /*initialize edited base currency code*/ {
            editedBaseCurrencyCodeSubject = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(setting.baseCurrencyCode)
            editedBaseCurrencyCodePublisher = editedBaseCurrencyCodeSubject.removeDuplicates()
                .eraseToAnyPublisher()
        }
        
        do /*initialize edited currency of interest*/ {
            editedCurrencyCodeOfInterestSubject = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(setting.currencyCodeOfInterest)
            editedCurrencyCodeOfInterestPublisher = editedCurrencyCodeOfInterestSubject.removeDuplicates().eraseToAnyPublisher()
        }
        
        // has changes
        do {
            let numberOfDaysHasChanges = editedNumberOfDaysPublisher.map { $0 != setting.numberOfDays }
            let baseCurrencyCodeHasChanges = editedBaseCurrencyCodePublisher.map { $0 != setting.baseCurrencyCode }
            let currencyCodeOfInterestHasChanges = editedCurrencyCodeOfInterestPublisher.map { $0 != setting.currencyCodeOfInterest }
            hasChangesToSave = Publishers.CombineLatest3(numberOfDaysHasChanges, baseCurrencyCodeHasChanges, currencyCodeOfInterestHasChanges)
                .map { $0 || $1 || $2 }
                .eraseToAnyPublisher()
        }
        
        attemptToCancelSubject = PassthroughSubject<Void, Never>()
        
        cancellationConfirmation = attemptToCancelSubject.withLatestFrom(hasChangesToSave)
            .compactMap { _, hasChangeToSave in hasChangeToSave ? () : nil }
            .eraseToAnyPublisher()
        
        cancelSubject = PassthroughSubject<Void, Never>()
        
        saveSubject = PassthroughSubject<Void, Never>()
        
        // initialization is complete
        
        saveSubject
            .withLatestFrom(editedNumberOfDaysPublisher)
            .map { $1 }
            .withLatestFrom(editedBaseCurrencyCodePublisher)
            .withLatestFrom(editedCurrencyCodeOfInterestPublisher)
            .map { (numberOfDays: $0.0, baseCurrencyCode: $0.1, currencyCodeOfInterest: $1) }
            .subscribe(saveSettingSubscriber)
        
        cancelSubject
            .subscribe(cancelSubscriber)
    }
    
    // MARK: - properties
    private let editedNumberOfDaysSubject: CurrentValueSubject<Int, Never>
    let editedNumberOfDaysPublisher: AnyPublisher<Int, Never>
    
    private let editedBaseCurrencyCodeSubject: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    let editedBaseCurrencyCodePublisher: AnyPublisher<ResponseDataModel.CurrencyCode, Never>
    
    private let editedCurrencyCodeOfInterestSubject: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    let editedCurrencyCodeOfInterestPublisher: AnyPublisher<Set<ResponseDataModel.CurrencyCode>, Never>
    
    let hasChangesToSave: AnyPublisher<Bool, Never>
    
    private let attemptToCancelSubject: PassthroughSubject<Void, Never>
    
    let cancellationConfirmation: AnyPublisher<Void, Never>
    
    let currencyDescriber: CurrencyDescriberProtocol
    
    // MARK: - properties used to communicate with `ResultModel`
    private let cancelSubject: PassthroughSubject<Void, Never>
    
    private let saveSubject: PassthroughSubject<Void, Never>
}

// MARK: - Confirming BaseSettingModel
extension SettingModel: BaseSettingModel {
    var editedNumberOfDays: Int { editedNumberOfDaysSubject.value }
    
    var editedBaseCurrencyCode: ResponseDataModel.CurrencyCode { editedBaseCurrencyCodeSubject.value }
    
    var editedCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> { editedCurrencyCodeOfInterestSubject.value }
    
    func attemptToCancel() {
        attemptToCancelSubject.send()
    }
    
    func cancel() {
        cancelSubject.send()
    }
    
    func save() {
        saveSubject.send()
    }
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel {
        let baseCurrencySelectionStrategy: BaseCurrencySelectionStrategy = BaseCurrencySelectionStrategy(
            baseCurrencyCode: editedBaseCurrencyCode,
            selectedBaseCurrencyCode: AnySubscriber(editedBaseCurrencyCodeSubject)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: baseCurrencySelectionStrategy)
    }
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel {
        let currencyOfInterestSelectionStrategy: CurrencyOfInterestSelectionStrategy = CurrencyOfInterestSelectionStrategy(
            currencyCodeOfInterest: editedCurrencyCodeOfInterestSubject.value,
            selectedCurrencyCodeOfInterest: AnySubscriber(editedCurrencyCodeOfInterestSubject)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: currencyOfInterestSelectionStrategy)
    }
}

extension SettingModel {
    func set(editedNumberOfDays: Int) {
        editedNumberOfDaysSubject.send(editedNumberOfDays)
    }
}
