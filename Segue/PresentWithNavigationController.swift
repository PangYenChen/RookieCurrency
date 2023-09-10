import UIKit

class PresentWithNavigationController: UIStoryboardSegue {
    override func perform() {
        let navigationController = UINavigationController(rootViewController: destination)
        source.present(navigationController, animated: true)
        
        navigationController.presentationController?.delegate = destination as? UIAdaptivePresentationControllerDelegate
    }
}
