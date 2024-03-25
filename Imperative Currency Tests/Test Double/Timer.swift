import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    final class Timer: TimerProtocol {
        // MARK: - initializer
        init() {}
        
        // MARK: - property
        private var block: (() -> Void)?
    }
}

// MARK: - instance methods
extension TestDouble.Timer {
    func scheduledTimer(withTimeInterval interval: TimeInterval, block: @escaping @Sendable () -> Void) {
        self.block = block
    }
    
    func invalidate() {
        block = nil
    }
    
    func executeBlock() {
        block?()
        block = nil
    }
}
