import Foundation
import Combine

class SettingModel {
    let editedNumberOfDays: CurrentValueSubject<Int, Never>
    
    let editedBaseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    let editedCurrencyCodeOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    let hasChangesToSave: AnyPublisher<Bool, Never>
    
    let currencyDescriber: CurrencyDescriber
    
    // MARK: - properties used to communicate with `ResultModel`
    private let cancelSubject: PassthroughSubject<Void, Never>
    
    private let saveSubject: PassthroughSubject<Void, Never>
    
    init(setting: BaseResultModel.Setting,
         settingSubscriber: AnySubscriber<BaseResultModel.Setting, Never>,
         cancelSubscriber: AnySubscriber<Void, Never>,
         currencyDescriber: CurrencyDescriber = SupportedCurrencyManager.shared) {
        self.currencyDescriber = currencyDescriber
        editedNumberOfDays = CurrentValueSubject<Int, Never>(setting.numberOfDays)
        
        editedBaseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(setting.baseCurrencyCode)
        
        editedCurrencyCodeOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(setting.currencyCodeOfInterest)
        
        // has changes
        do {
            let numberOfDaysHasChanges = editedNumberOfDays.map { $0 != setting.numberOfDays }
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
            .withLatestFrom(editedNumberOfDays)
            .map { $1 }
            .withLatestFrom(editedBaseCurrencyCode)
            .withLatestFrom(editedCurrencyCodeOfInterest)
            .map { (numberOfDays: $0.0, baseCurrencyCode: $0.1, currencyCodeOfInterest: $1) }
            .subscribe(settingSubscriber)
        
        cancelSubject
            .subscribe(cancelSubscriber)
    }
}

// MARK: - Confirming BaseSettingModel
extension SettingModel: BaseSettingModel {
    func cancel() {
        cancelSubject.send()
    }
    
    func save() {
        saveSubject.send()
    }
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel {
        let baseCurrencySelectionStrategy = BaseCurrencySelectionStrategy(
            baseCurrencyCode: editedBaseCurrencyCode.value,
            selectedBaseCurrencyCode: AnySubscriber(editedBaseCurrencyCode)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: baseCurrencySelectionStrategy)
    }
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel {
        let currencyOfInterestSelectionStrategy = CurrencyOfInterestSelectionStrategy(
            currencyCodeOfInterest: editedCurrencyCodeOfInterest.value,
            selectedCurrencyCodeOfInterest: AnySubscriber(editedCurrencyCodeOfInterest)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: currencyOfInterestSelectionStrategy)
    }
}
