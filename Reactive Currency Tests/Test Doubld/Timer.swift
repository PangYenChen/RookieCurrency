import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    final class Timer {
        private var wrappedSubject: PassthroughSubject<Void, Never>?
    }
}

// MARK: - TimerProtocol
extension TestDouble.Timer: TimerProtocol {
    func makeTimerPublisher(every interval: TimeInterval) -> AnyPublisher<Void, Never> {
        let wrappedSubject: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>()
        self.wrappedSubject = wrappedSubject
        
        return wrappedSubject
            .handleEvents(receiveCancel: { [unowned self] in self.wrappedSubject = nil })
            .eraseToAnyPublisher()
    }
}

extension TestDouble.Timer {
    func publish() {
        wrappedSubject?.send()
    }
}
