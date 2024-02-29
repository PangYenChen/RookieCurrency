import Foundation

class TimerProxy: TimerProtocol {
    // MARK: - initializer
    init() {}

    // MARK: - private property
    private var timer: Timer?
    
    func scheduledTimer(withTimeInterval interval: TimeInterval, block: @escaping @Sendable () -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in block() }
        timer?.fire()
    }
    
    func invalidate() {
        timer?.invalidate()
        timer = nil
    }
}
