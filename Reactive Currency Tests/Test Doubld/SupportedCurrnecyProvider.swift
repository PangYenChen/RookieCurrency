@testable import ReactiveCurrency

import Combine

extension TestDouble {
    class SupportedCurrencyProvider: SupportedCurrencyProviderProtocol {
        init() {
            passthroughSubject = nil
            numberOfFunctionCall = 0
        }
        
        private var passthroughSubject: PassthroughSubject<ResponseDataModel.SupportedSymbols, Error>?
        private(set) var numberOfFunctionCall: Int
        
        func supportedCurrencyPublisher(traceIdentifier: String) -> AnyPublisher<ResponseDataModel.SupportedSymbols, Error> {
            numberOfFunctionCall += 1
            
            let passthroughSubject: PassthroughSubject<ResponseDataModel.SupportedSymbols, Error> = PassthroughSubject<ResponseDataModel.SupportedSymbols, Error>()
            
            self.passthroughSubject = passthroughSubject
            
            return passthroughSubject.eraseToAnyPublisher()
        }
        
        func publish(_ output: ResponseDataModel.SupportedSymbols) {
            passthroughSubject?.send(output)
            passthroughSubject?.send(completion: .finished)
            
            passthroughSubject = nil
        }
        
        func publish(completion: Subscribers.Completion<Error>) {
            passthroughSubject?.send(completion: completion)
            
            passthroughSubject = nil
        }
    }
}
