import UIKit
import Combine

class SettingTableViewController: BaseSettingTableViewController {
    
    // MARK: - properties
    override var editedNumberOfDayString: String { String(editedNumberOfDay.value) }
    
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
    
    private let editedNumberOfDay: CurrentValueSubject<Int, Never>
    
    private let editedBaseCurrency: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    private let editedCurrencyOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    private let hasChanges: AnyPublisher<Bool, Never>
    
    private let didTapCancelButtonSubject: PassthroughSubject<Void, Never>
    
    private let cancelSubject: PassthroughSubject<Void, Never>
    
    private let didTapSaveButtonSubject: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   userSetting: BaseResultModel.UserSetting,
                   settingSubscriber: AnySubscriber<(numberOfDay: Int, baseCurrency: ResponseDataModel.CurrencyCode, currencyOfInterest: Set<ResponseDataModel.CurrencyCode>), Never>,
                   cancelSubscriber: AnySubscriber<Void, Never>) {
        
        editedNumberOfDay = CurrentValueSubject<Int, Never>(userSetting.numberOfDay)
        
        editedBaseCurrency = CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>(userSetting.baseCurrency)
        
        editedCurrencyOfInterest = CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>(userSetting.currencyOfInterest)
        
        didTapCancelButtonSubject = PassthroughSubject<Void, Never>()
        
        cancelSubject = PassthroughSubject<Void, Never>()
        
        didTapSaveButtonSubject = PassthroughSubject<Void, Never>()
        
        // has changes
        do {
            let numberOfDayHasChanges = editedNumberOfDay.map { $0 != userSetting.numberOfDay }
            let baseCurrencyHasChanges = editedBaseCurrency.map { $0 != userSetting.baseCurrency }
            let currencyOfInterestHasChanges = editedCurrencyOfInterest.map { $0 != userSetting.currencyOfInterest }
            hasChanges = Publishers.CombineLatest3(numberOfDayHasChanges, baseCurrencyHasChanges, currencyOfInterestHasChanges)
                .map { $0 || $1 || $2 }
                .eraseToAnyPublisher()
        }
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
        
        stepper.value = Double(userSetting.numberOfDay)
        
        didTapCancelButtonSubject
            .withLatestFrom(hasChanges)
            .sink { [unowned self] _, hasChanges in hasChanges ? presentCancelAlert(showingSave: false) : cancel() }
            .store(in: &anyCancellableSet)
        
        didTapSaveButtonSubject
            .withLatestFrom(editedNumberOfDay)
            .map { $1 }
            .withLatestFrom(editedBaseCurrency)
            .withLatestFrom(editedCurrencyOfInterest)
            .map { (numberOfDay: $0.0, baseCurrency: $0.1, currencyOfInterest: $1) }
            .subscribe(settingSubscriber)
        
        cancelSubject
            .subscribe(cancelSubscriber)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editedNumberOfDay
            .dropFirst()
            .sink { [unowned self] _ in
                
                let numberOfDayRow = IndexPath(row: Row.numberOfDay.rawValue, section: 0)
                
                guard let cell = tableView.cellForRow(at: numberOfDayRow) else {
                    assertionFailure("###, \(#function), \(self), 拿不到設定 number of day 的 cell。")
                    return
                }
                
                guard var contentConfiguration = cell.contentConfiguration as? UIListContentConfiguration else {
                    assertionFailure("###, \(#function), \(self), 在 data source method 中，cell 的 content configuration 應該要是 UIListContentConfiguration，但是中途被改掉了。")
                    return
                }
                
                contentConfiguration.secondaryText = editedNumberOfDayString
                
                cell.contentConfiguration = contentConfiguration
            }
            .store(in: &anyCancellableSet)
        
        hasChanges
            .sink { [unowned self] hasChanges in
                saveButton.isEnabled = hasChanges
                isModalInPresentation = hasChanges
            }
            .store(in: &anyCancellableSet)
    }
    
    override func stepperValueDidChange() {
        editedNumberOfDay.send(Int(stepper.value))
    }
    
    override func cancel() {
        super.cancel()
        cancelSubject.send()
    }
    
    @IBAction override func save() {
        didTapSaveButtonSubject.send()
        super.save()
    }
    
    @IBAction private func didTapCancelButton() {
        didTapCancelButtonSubject.send()
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let strategy = CurrencyTableViewController
            .BaseCurrencySelectionStrategy(baseCurrencyCode: editedBaseCurrency.value,
                                           selectedBaseCurrencyCode: AnySubscriber(editedBaseCurrency))
        
        return CurrencyTableViewController(coder: coder, strategy: strategy)
    }
    
    override func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let strategy = CurrencyTableViewController
            .CurrencyOfInterestSelectionStrategy(currencyOfInterest: editedCurrencyOfInterest.value,
                                                 selectedCurrencyOfInterest: AnySubscriber(editedCurrencyOfInterest))
        
        return CurrencyTableViewController(coder: coder, strategy: strategy)
    }
}
