@testable import ReactiveCurrency
import Combine

final class FakeFetcher: FetcherProtocol {
    
    private(set) var numberOfMethodCall = 0
    
    func publisher<Endpoint>(for endPoint: Endpoint) -> AnyPublisher<Endpoint.ResponseType, Error> where Endpoint : ReactiveCurrency.EndpointProtocol {
        // This is a fake instance, and any of it's method should not be called.
        
        numberOfMethodCall += 1
        
        // the following code should be dead code
        return Empty().eraseToAnyPublisher()
    }
}
