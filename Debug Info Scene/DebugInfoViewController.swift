import UIKit

class DebugInfoViewController: UIViewController {
#if DEBUG
    // MARK: - IBOutlet
    @IBOutlet private var apiKeyUsageProgressView: UIProgressView!
    
    @IBOutlet private var homeDirectoryTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyUsageProgressView.setProgress(Float(Fetcher.shared.apiKeysUsageRatio), animated: true)
        homeDirectoryTextView.text = NSHomeDirectory()
    }
    
    @IBAction private func copyDocumentDirectory(_ sender: Any) {
        UIPasteboard.general.string = NSHomeDirectory()
    }
#endif
}
