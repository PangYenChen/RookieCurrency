import Foundation

protocol EndpointProtocol {
    associatedtype ResponseType: Decodable
    
    var url: URL { get }
}

protocol PartialPathProvider: EndpointProtocol {
    var partialPath: String { get }
}

extension PartialPathProvider {
    
    var url: URL { (urlComponents?.url)! }
    
    var urlComponents: URLComponents? {
        var urlComponents = Fetcher.urlComponents
        urlComponents?.path += partialPath
        return urlComponents
    }
}

protocol BaseOnTWD: PartialPathProvider {}

extension BaseOnTWD {
    var url: URL {
        var urlComponents = urlComponents
        urlComponents?.queryItems = [URLQueryItem(name: "base", value: "TWD")]
        
        return (urlComponents?.url)!
    }
}
