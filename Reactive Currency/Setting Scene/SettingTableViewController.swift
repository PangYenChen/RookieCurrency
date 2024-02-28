import UIKit
import Combine

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder,
          model: SettingModel) {
        self.settingModel = model
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, baseSettingModel: model)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: 這些東西在第一次進來畫面，table veiw本身會 load 一次，這裡會不會多load一次？
        settingModel.editedNumberOfDaysPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in updateNumberOfDaysRow() }
            .store(in: &anyCancellableSet)
        
        settingModel.editedBaseCurrencyCodePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] _ in reloadBaseCurrencyRow() })
            .store(in: &anyCancellableSet)
        
        settingModel.editedCurrencyCodeOfInterestPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] _ in reloadCurrencyOfInterestRow() })
            .store(in: &anyCancellableSet)
        
        settingModel.hasChangesToSave
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: self.updateFor(hasChangesToSave:))
            .store(in: &anyCancellableSet)
        
        settingModel.cancellationConfirmation
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in presentDismissalConfirmation(withSaveOption: false) }
            .store(in: &anyCancellableSet)
    }
    
    // MARK: - private properties
    private let settingModel: SettingModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - override abstract method
    override func stepperValueDidChange() {
        settingModel.set(editedNumberOfDays: Int(getStepperValue()))
    }
    
    override func didTapCancelButton(_ sender: UIBarButtonItem) {
        settingModel.attemptToCancel()
    }
}
