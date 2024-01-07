@testable import ImperativeCurrency

extension TestDouble {
    final class Fetcher: FetcherProtocol {
        
        private(set) var numberOfMethodCall = 0
        
        func fetch<Endpoint: EndpointProtocol>(
            _ endpoint: Endpoint,
            completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
        ) {
                // This is a fake instance, and any of it's method should not be called.
            
            numberOfMethodCall += 1
        }
    }    
}
