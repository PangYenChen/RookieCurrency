import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class LatestRateProvider: LatestRateProviderProtocol {
        // MARK: - initializer
        init() {
            passthroughSubject = PassthroughSubject<ResponseDataModel.LatestRate, Error>()
        }
        
        // MARK: - private property
        private let passthroughSubject: PassthroughSubject<ResponseDataModel.LatestRate, Error>
        
        // MARK: - instance method
        func latestRatePublisher() -> AnyPublisher<ResponseDataModel.LatestRate, Error> {
            passthroughSubject.eraseToAnyPublisher()
        }
        
        func publish(_ output: ResponseDataModel.LatestRate) {
            passthroughSubject.send(output)
        }
        
        func publish(completion: Subscribers.Completion<Error>) {
            passthroughSubject.send(completion: completion)
        }
    }
}
