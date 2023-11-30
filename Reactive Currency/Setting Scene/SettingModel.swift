import Foundation
import Combine

class SettingModel: BaseSettingModel {
    let editedNumberOfDays: CurrentValueSubject<Int, Never>
    
    let editedBaseCurrency: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    let editedCurrencyOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    let hasChangesToSave: AnyPublisher<Bool, Never>
    
    // MARK: - properties used to communicate with `ResultModel`
    private let cancelSubject: PassthroughSubject<Void, Never>
    
    private let saveSubject: PassthroughSubject<Void, Never>
    
    init(userSetting: BaseResultModel.UserSetting,
         settingSubscriber: AnySubscriber<BaseResultModel.UserSetting, Never>,
         cancelSubscriber: AnySubscriber<Void, Never>) {
        editedNumberOfDays = CurrentValueSubject<Int, Never>(userSetting.numberOfDay)
        
        editedBaseCurrency = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(userSetting.baseCurrency)
        
        editedCurrencyOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(userSetting.currencyOfInterest)
        
        // has changes
        do {
            let numberOfDayHasChanges = editedNumberOfDays.map { $0 != userSetting.numberOfDay }
            let baseCurrencyHasChanges = editedBaseCurrency.map { $0 != userSetting.baseCurrency }
            let currencyOfInterestHasChanges = editedCurrencyOfInterest.map { $0 != userSetting.currencyOfInterest }
            hasChangesToSave = Publishers.CombineLatest3(numberOfDayHasChanges, baseCurrencyHasChanges, currencyOfInterestHasChanges)
                .map { $0 || $1 || $2 }
                .eraseToAnyPublisher()
        }
    
        cancelSubject = PassthroughSubject<Void, Never>()
        
        saveSubject = PassthroughSubject<Void, Never>()
        
        // finish initialization
        
        saveSubject
            .withLatestFrom(editedNumberOfDays)
            .map { $1 }
            .withLatestFrom(editedBaseCurrency)
            .withLatestFrom(editedCurrencyOfInterest)
            .map { (numberOfDay: $0.0, baseCurrency: $0.1, currencyOfInterest: $1) }
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
