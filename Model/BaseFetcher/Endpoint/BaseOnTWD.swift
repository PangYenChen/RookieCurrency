import Foundation

protocol BaseOnTWD: PartialPathProvider {}

extension BaseOnTWD {
    var urlResult: Result<URL, Error> {
        var urlComponents: URLComponents = urlComponents
        urlComponents.queryItems = [URLQueryItem(name: "base", value: "TWD")]
        
        if let url = urlComponents.url {
            return .success(url)
        }
        else {
            return .failure(URLError(URLError.Code.badURL))
        }
    }
}
