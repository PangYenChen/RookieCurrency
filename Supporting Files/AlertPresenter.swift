import UIKit

protocol AlertPresenter {
    func presentAlert(error: Error, handler: ((UIAlertAction) -> Void)?)
    func presentAlert(message: String, handler: ((UIAlertAction) -> Void)?)
}

extension AlertPresenter where Self: UIViewController {
    
    func presentAlert(message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alertController: UIAlertController
        
        // alert controller
        do {
            let alertTitle = R.string.share.alertTitle()
            alertController = UIAlertController(title: alertTitle,
                                                message: message,
                                                preferredStyle: .alert)
        }
        
        // alert action
        do {
            let alertActionTitle = R.string.share.alertActionTitle()
            let alertAction = UIAlertAction(title: alertActionTitle, style: .cancel, handler: handler)
            alertController.addAction(alertAction)
        }
        
        present(alertController, animated: true)
    }
    
    func presentAlert(error: Error, handler: ((UIAlertAction) -> Void)? = nil) {
        presentAlert(message: error.localizedDescription, handler: handler)
    }
}
