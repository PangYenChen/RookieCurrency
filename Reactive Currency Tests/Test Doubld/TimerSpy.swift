import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    final class TimerSpy {
        private var wrappedSubject: PassthroughSubject<Void, Never>?
    }
}

// MARK: - TimerProtocol
extension TestDouble.TimerSpy: TimerProtocol {
    func makeTimerPublisher(every interval: TimeInterval) -> AnyPublisher<Void, Never> {
        let wrappedSubject = PassthroughSubject<Void, Never>()
        self.wrappedSubject = wrappedSubject
        
        return wrappedSubject
            .handleEvents(receiveCancel: { [unowned self] in self.wrappedSubject = nil })
            .eraseToAnyPublisher()
    }
}

extension TestDouble.TimerSpy {
    func publish() {
        wrappedSubject?.send()
    }
}
