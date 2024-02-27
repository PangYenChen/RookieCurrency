import UIKit

enum UIConfiguration {}

extension UIConfiguration {
    enum TableView {
        static let cellContentDirectionalLayoutMargins: NSDirectionalEdgeInsets = {
            let topInset: CGFloat = 8
            let leadingInset: CGFloat = 16
            let bottomInset: CGFloat = 8
            let trailingInset: CGFloat = 16
            
            return NSDirectionalEdgeInsets(top: topInset, leading: leadingInset, bottom: bottomInset, trailing: trailingInset)
        }()
        
        static let cellContentTextToSecondaryTextVerticalPadding: CGFloat = 4
    }
}
