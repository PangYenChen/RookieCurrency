import UIKit

protocol AlertPresenter {
    func presentAlert(title: String, error: Error, handler: ((UIAlertAction) -> Void)?)
    func presentAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?)
}

extension AlertPresenter where Self: UIViewController {
    
    func presentAlert(title: String = R.string.share.alertTitle(),
                      message: String,
                      handler: ((UIAlertAction) -> Void)? = nil) {
        let alertController: UIAlertController
        
        // alert controller
        do {
            alertController = UIAlertController(title: title,
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
    
    func presentAlert(title: String = R.string.share.alertTitleForError(),
                      error: Error,
                      handler: ((UIAlertAction) -> Void)? = nil) {
        presentAlert(title: title, message: error.localizedDescription, handler: handler)
    }
}
