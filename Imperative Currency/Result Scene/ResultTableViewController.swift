import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored property
    private let model: ResultModel
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        model = ResultModel()
        
        super.init(coder: coder, baseResultModel: model)
    }
    
    required init?(coder: NSCoder, baseResultModel: BaseResultModel) {
        fatalError("init(coder:baseResultModel:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.stateHandler = self.updateUIFor(_:)
        model.resumeAutoUpdatingState()
    }
    
    // MARK: - navigation
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        model.suspendAutoUpdatingState()
        
        let userSetting = (numberOfDay: model.numberOfDays, baseCurrency: model.baseCurrencyCode, currencyOfInterest: model.currencyCodeOfInterest)
        
        return SettingTableViewController(
            coder: coder,
            userSetting: userSetting
        ) { [unowned self] editedNumberOfDays, editedBaseCurrencyCode, editedCurrencyCodeOfInterest in
            model.resumeAutoUpdatingStateFor(numberOfDays: editedNumberOfDays,
                                             baseCurrencyCode: editedBaseCurrencyCode,
                                             currencyCodeOfInterest: editedCurrencyCodeOfInterest,
                                             completionHandler: updateUIFor(_:))
        } cancelCompletionHandler: { [unowned self] in
            // TODO:
//            model.resumeAutoUpdatingState(completionHandler: updateUIFor(_:))
        }
    }
}
