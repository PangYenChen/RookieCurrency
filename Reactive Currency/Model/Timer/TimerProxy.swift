import Foundation
import Combine

class TimerProxy: TimerProtocol {
    func makeTimerPublisher(every interval: TimeInterval) -> AnyPublisher<Void, Never> {
        Timer.publish(every: interval, on: RunLoop.main, in: .default)
            .autoconnect()
            .map { _ in }
            .prepend(()) // start immediately after subscribing
            .eraseToAnyPublisher()
    }
}
