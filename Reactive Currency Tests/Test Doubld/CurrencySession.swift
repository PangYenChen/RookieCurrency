import Combine
import Foundation

@testable import ReactiveCurrency

extension TestDouble {
    class CurrencySession: CurrencySessionProtocol {
        init() {
            passthroughSubjects = []
        }
        
        private var passthroughSubjects: [PassthroughSubject<(data: Data, response: URLResponse), URLError>]
        
        func currencyDataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
            let passthroughSubject: PassthroughSubject<(data: Data, response: URLResponse), URLError> = PassthroughSubject<(data: Data, response: URLResponse), URLError>()
            passthroughSubjects.append(passthroughSubject)
            
            return passthroughSubject.eraseToAnyPublisher()
        }
        
        func publish(_ output: (data: Data, response: URLResponse)) {
            guard !passthroughSubjects.isEmpty else { return }
            let passthroughSubject: PassthroughSubject<(data: Data, response: URLResponse), URLError> = passthroughSubjects.removeFirst()
            passthroughSubject.send(output)
            passthroughSubject.send(completion: .finished)
        }
        
        func publish(completion: Subscribers.Completion<URLError>) {
            guard !passthroughSubjects.isEmpty else { return }
            let passthroughSubject: PassthroughSubject<(data: Data, response: URLResponse), URLError> = passthroughSubjects.removeFirst()
            passthroughSubject.send(completion: completion)
        }
    }
}
