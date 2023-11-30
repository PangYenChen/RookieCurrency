import Foundation
import Combine

class SettingModel: BaseSettingModel {
    let editedNumberOfDays: CurrentValueSubject<Int, Never>
    
    let editedBaseCurrencyCode: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    let editedCurrencyOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    let hasChangesToSave: AnyPublisher<Bool, Never>
    
    // MARK: - properties used to communicate with `ResultModel`
    private let cancelSubject: PassthroughSubject<Void, Never>
    
    private let saveSubject: PassthroughSubject<Void, Never>
    
    init(userSetting: BaseResultModel.UserSetting,
         settingSubscriber: AnySubscriber<BaseResultModel.UserSetting, Never>,
         cancelSubscriber: AnySubscriber<Void, Never>) {
        editedNumberOfDays = CurrentValueSubject<Int, Never>(userSetting.numberOfDays)
        
        editedBaseCurrencyCode = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(userSetting.baseCurrencyCode)
        
        editedCurrencyOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(userSetting.currencyOfInterest)
        
        // has changes
        do {
            let numberOfDaysHasChanges = editedNumberOfDays.map { $0 != userSetting.numberOfDays }
            let baseCurrencyCodeHasChanges = editedBaseCurrencyCode.map { $0 != userSetting.baseCurrencyCode }
            let currencyOfInterestHasChanges = editedCurrencyOfInterest.map { $0 != userSetting.currencyOfInterest }
            hasChangesToSave = Publishers.CombineLatest3(numberOfDaysHasChanges, baseCurrencyCodeHasChanges, currencyOfInterestHasChanges)
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
            .withLatestFrom(editedCurrencyOfInterest)
            .map { (numberOfDays: $0.0, baseCurrencyCode: $0.1, currencyOfInterest: $1) }
            .subscribe(settingSubscriber)
        
        cancelSubject
            .subscribe(cancelSubscriber)
    }
    
    // MARK: - hook methods
    override func cancel() {
        cancelSubject.send()
    }
    
    override func save() {
        saveSubject.send()
    }
}
