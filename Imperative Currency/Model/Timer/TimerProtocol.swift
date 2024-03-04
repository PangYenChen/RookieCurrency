import Foundation

protocol TimerProtocol {
    func scheduledTimer(withTimeInterval interval: TimeInterval, block: @escaping @Sendable () -> Void)
    
    func invalidate()
}
