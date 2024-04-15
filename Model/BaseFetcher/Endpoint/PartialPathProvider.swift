import Foundation

protocol PartialPathProvider: EndpointProtocol {
    var partialPath: String { get }
}

extension PartialPathProvider {
    var url: URL { (urlComponents?.url)! }
    
    var urlComponents: URLComponents? {
        var urlComponents: URLComponents? = Fetcher.urlComponents
        urlComponents?.path += partialPath
        return urlComponents
    }
}
