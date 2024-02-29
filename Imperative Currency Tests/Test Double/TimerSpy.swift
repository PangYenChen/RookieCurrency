import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class TimerSpy: TimerProtocol {
        // MARK: - initializer
        init() {}
        
        // MARK: - property
        var block: (() -> Void)?
    }
}


// MARK: - instance methods
extension TestDouble.TimerSpy {
    func scheduledTimer(withTimeInterval interval: TimeInterval, block: @escaping @Sendable () -> Void) {
        self.block = block
    }
    
    func invalidate() {
        block = nil
    }
}
