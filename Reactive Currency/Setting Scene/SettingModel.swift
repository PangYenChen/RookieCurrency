import Foundation
import Combine

class SettingModel: BaseSettingModel {
    // MARK: - override super class' computed properties
    override var editedNumberOfDaysString: String { String(editedNumberOfDays.value) }
    
    override var editedBaseCurrencyString: String {
        Locale.autoupdatingCurrent.localizedString(forCurrencyCode: editedBaseCurrency.value) ??
        AppUtility.supportedSymbols?[editedBaseCurrency.value] ??
        editedBaseCurrency.value
    }
    
    override var editedCurrencyOfInterestString: String {
        let editedCurrencyDisplayString = editedCurrencyOfInterest.value
            .map { currencyCode in
                Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ??
                AppUtility.supportedSymbols?[currencyCode] ??
                currencyCode
            }
            .sorted()
        
        return ListFormatter.localizedString(byJoining: editedCurrencyDisplayString)
    }
    
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
        
    }
    
}
