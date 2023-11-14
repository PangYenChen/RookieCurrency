import Foundation
import Combine

class SettingModel {
    let editedNumberOfDays: CurrentValueSubject<Int, Never>
    
    let editedBaseCurrency: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    let editedCurrencyOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    let hasChanges: AnyPublisher<Bool, Never>
    
    let didTapCancelButtonSubject: PassthroughSubject<Void, Never>
    
    let cancelSubject: PassthroughSubject<Void, Never>
    
    let didTapSaveButtonSubject: PassthroughSubject<Void, Never>
    
    init(userSetting: BaseResultModel.UserSetting,
         settingSubscriber: AnySubscriber<(numberOfDay: Int,
                                           baseCurrency: ResponseDataModel.CurrencyCode,
                                           currencyOfInterest: Set<ResponseDataModel.CurrencyCode>), Never>,
         cancelSubscriber: AnySubscriber<Void, Never>) {
        editedNumberOfDays = CurrentValueSubject<Int, Never>(userSetting.numberOfDay)
        
        editedBaseCurrency = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(userSetting.baseCurrency)
        
        editedCurrencyOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(userSetting.currencyOfInterest)
        
        // has changes
        do {
            let numberOfDayHasChanges = editedNumberOfDays.map { $0 != userSetting.numberOfDay }
            let baseCurrencyHasChanges = editedBaseCurrency.map { $0 != userSetting.baseCurrency }
            let currencyOfInterestHasChanges = editedCurrencyOfInterest.map { $0 != userSetting.currencyOfInterest }
            hasChanges = Publishers.CombineLatest3(numberOfDayHasChanges, baseCurrencyHasChanges, currencyOfInterestHasChanges)
                .map { $0 || $1 || $2 }
                .eraseToAnyPublisher()
        }
        
        didTapCancelButtonSubject = PassthroughSubject<Void, Never>()
        
        cancelSubject = PassthroughSubject<Void, Never>()
        
        didTapSaveButtonSubject = PassthroughSubject<Void, Never>()
        
        // finish initialization
        
        didTapSaveButtonSubject
            .withLatestFrom(editedNumberOfDays)
            .map { $1 }
            .withLatestFrom(editedBaseCurrency)
            .withLatestFrom(editedCurrencyOfInterest)
            .map { (numberOfDay: $0.0, baseCurrency: $0.1, currencyOfInterest: $1) }
            .subscribe(settingSubscriber)
        
        cancelSubject
            .subscribe(cancelSubscriber)
    }
}
