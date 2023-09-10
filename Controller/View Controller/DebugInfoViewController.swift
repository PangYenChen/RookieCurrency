import UIKit

class DebugInfoViewController: UIViewController {
#if DEBUG
    // MARK: - IBOutlet
    @IBOutlet weak var apiKeyUsageProgressView: UIProgressView!
    
    @IBOutlet weak var homeDirectoryTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyUsageProgressView.setProgress(Float(Fetcher.shared.apiKeysUsageRatio), animated: true)
        homeDirectoryTextView.text = NSHomeDirectory()
    }
    @IBAction func copyDocumentDirectory(_ sender: Any) {
        UIPasteboard.general.string = NSHomeDirectory()
    }
#endif
}
