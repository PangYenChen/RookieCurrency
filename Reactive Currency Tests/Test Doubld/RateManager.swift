import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class RateManager: RateManagerProtocol {
        private(set) var numberOfDays: Int?
        
        private var passthroughSubject: PassthroughSubject<BaseRateManager.RateTuple, Error>?
        
        init() {
            numberOfDays = nil
            passthroughSubject = nil
        }
        
        func ratePublisher(numberOfDays: Int) -> AnyPublisher<BaseRateManager.RateTuple, Error> {
            self.numberOfDays = numberOfDays
            let passthroughSubject: PassthroughSubject<BaseRateManager.RateTuple, Error> = PassthroughSubject<BaseRateManager.RateTuple, Error>()
            self.passthroughSubject = passthroughSubject
            
            return passthroughSubject.eraseToAnyPublisher()
        }
        
        func publish(_ output: BaseRateManager.RateTuple) {
            passthroughSubject?.send(output)
            passthroughSubject?.send(completion: .finished)
            
            passthroughSubject = nil
        }
        
        func publish(completion: Subscribers.Completion<any Error>) {
            passthroughSubject?.send(completion: completion)
            passthroughSubject = nil
        }
    }
}
