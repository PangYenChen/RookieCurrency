import Foundation
import Combine

protocol TimerProtocol {
    func makeTimerPublisher(every interval: TimeInterval) -> AnyPublisher<Void, Never>
}
