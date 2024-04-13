import Foundation

protocol BaseOnTWD: PartialPathProvider {}

extension BaseOnTWD {
    var url: URL {
        var urlComponents: URLComponents? = urlComponents
        urlComponents?.queryItems = [URLQueryItem(name: "base", value: "TWD")]
        
        return (urlComponents?.url)!
    }
}
