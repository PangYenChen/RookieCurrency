@testable import ReactiveCurrency
import Combine

extension TestDouble {
    final class Fetcher: FetcherProtocol {
        
        private(set) var numberOfMethodCall = 0
        
        func publisher<Endpoint>(for endPoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Error> where Endpoint: ReactiveCurrency.EndpointProtocol {
            // TODO: to be implemented
            
            numberOfMethodCall += 1
            
            return Empty().eraseToAnyPublisher()
        }
    }    
}
