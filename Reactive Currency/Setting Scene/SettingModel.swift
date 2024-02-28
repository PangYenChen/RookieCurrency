import Foundation
import Combine

class SettingModel {
    // MARK: - initializer
    init(setting: BaseResultModel.Setting,
         saveSettingSubscriber: AnySubscriber<BaseResultModel.Setting, Never>,
         cancelSubscriber: AnySubscriber<Void, Never>,
         currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared) {
        self.currencyDescriber = currencyDescriber
        
        do /*initialize number of days*/ {
            numberOfDaysSubject = CurrentValueSubject<Int, Never>(setting.numberOfDays)
            numberOfDaysDidChange = numberOfDaysSubject.removeDuplicates()
                .map { _ in }
                .eraseToAnyPublisher()
        }
        
        do /*initialize base currency code*/ {
            baseCurrencyCodeSubject = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(setting.baseCurrencyCode)
            baseCurrencyCodeDidChange = baseCurrencyCodeSubject.removeDuplicates()
                .map { _ in }
                .eraseToAnyPublisher()
        }
        
        do /*initialize currency of interest*/ {
            currencyCodeOfInterestSubject = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(setting.currencyCodeOfInterest)
            currencyCodeOfInterestDidChange = currencyCodeOfInterestSubject.removeDuplicates()
                .map { _ in }
                .eraseToAnyPublisher()
        }
        
        do /*initialize has modification*/ {
            let isNumberOfDaysModified: AnyPublisher<Bool, Never> = numberOfDaysSubject
                .map { $0 != setting.numberOfDays }
                .eraseToAnyPublisher()
            let isBaseCurrencyCodeModified: AnyPublisher<Bool, Never> = baseCurrencyCodeSubject
                .map { $0 != setting.baseCurrencyCode }
                .eraseToAnyPublisher()
            let isCurrencyCodeOfInterestModified: AnyPublisher<Bool, Never> = currencyCodeOfInterestSubject
                .map { $0 != setting.currencyCodeOfInterest }
                .eraseToAnyPublisher()
            
            hasModificationsToSave = Publishers.CombineLatest3(isNumberOfDaysModified, isBaseCurrencyCodeModified, isCurrencyCodeOfInterestModified)
                .map { $0 || $1 || $2 }
                .removeDuplicates()
                .eraseToAnyPublisher()
        }
        
        attemptToCancelSubject = PassthroughSubject<Void, Never>()
        
        cancellationConfirmation = attemptToCancelSubject.withLatestFrom(hasModificationsToSave)
            .compactMap { _, hasModificationsToSave in hasModificationsToSave ? () : nil }
            .eraseToAnyPublisher()
        
        cancelSubject = PassthroughSubject<Void, Never>()
        
        saveSubject = PassthroughSubject<Void, Never>()
        
        // initialization is complete
        
        saveSubject
            .withLatestFrom(numberOfDaysSubject)
            .map { $1 }
            .withLatestFrom(baseCurrencyCodeSubject)
            .withLatestFrom(currencyCodeOfInterestSubject)
            .map { (numberOfDays: $0.0, baseCurrencyCode: $0.1, currencyCodeOfInterest: $1) }
            .subscribe(saveSettingSubscriber)
        
        cancelSubject
            .subscribe(cancelSubscriber)
    }
    
    // MARK: - properties
    private let numberOfDaysSubject: CurrentValueSubject<Int, Never>
    let numberOfDaysDidChange: AnyPublisher<Void, Never>
    
    private let baseCurrencyCodeSubject: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    let baseCurrencyCodeDidChange: AnyPublisher<Void, Never>
    
    private let currencyCodeOfInterestSubject: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    let currencyCodeOfInterestDidChange: AnyPublisher<Void, Never>
    
    let hasModificationsToSave: AnyPublisher<Bool, Never>
    
    private let attemptToCancelSubject: PassthroughSubject<Void, Never>
    
    let cancellationConfirmation: AnyPublisher<Void, Never>
    
    let currencyDescriber: CurrencyDescriberProtocol
    
    // MARK: - properties used to communicate with `ResultModel`
    private let cancelSubject: PassthroughSubject<Void, Never>
    
    private let saveSubject: PassthroughSubject<Void, Never>
}

// MARK: - Confirming BaseSettingModel
extension SettingModel: BaseSettingModel {
    var numberOfDays: Int { numberOfDaysSubject.value }
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode { baseCurrencyCodeSubject.value }
    
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> { currencyCodeOfInterestSubject.value }
    
    func cancel() {
        cancelSubject.send()
    }
    
    func save() {
        saveSubject.send()
    }
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel {
        let baseCurrencySelectionStrategy: BaseCurrencySelectionStrategy = BaseCurrencySelectionStrategy(
            baseCurrencyCode: baseCurrencyCode,
            selectedBaseCurrencyCode: AnySubscriber(baseCurrencyCodeSubject)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: baseCurrencySelectionStrategy)
    }
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel {
        let currencyOfInterestSelectionStrategy: CurrencyOfInterestSelectionStrategy = CurrencyOfInterestSelectionStrategy(
            currencyCodeOfInterest: currencyCodeOfInterestSubject.value,
            selectedCurrencyCodeOfInterest: AnySubscriber(currencyCodeOfInterestSubject)
        )
        
        return CurrencySelectionModel(currencySelectionStrategy: currencyOfInterestSelectionStrategy)
    }
}

extension SettingModel {
    func set(numberOfDays: Int) {
        numberOfDaysSubject.send(numberOfDays)
    }
    
    func attemptToCancel() {
        attemptToCancelSubject.send()
    }
}
