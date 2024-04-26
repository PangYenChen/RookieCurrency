import Foundation

protocol PartialPathProvider: EndpointProtocol {
    var partialPath: String { get }
}

extension PartialPathProvider {
    var urlResult: Result<URL, Error> {
        if let url = urlComponents.url {
            return .success(url)
        }
        else {
            return .failure(URLError(URLError.Code.badURL))
        }
    }
    
    var urlComponents: URLComponents {
        var urlComponents: URLComponents = Fetcher.baseURLComponents
        urlComponents.path += partialPath
        return urlComponents
    }
}
