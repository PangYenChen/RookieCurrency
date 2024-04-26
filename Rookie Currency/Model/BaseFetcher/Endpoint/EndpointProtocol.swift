import Foundation

protocol EndpointProtocol {
    var urlResult: Result<URL, Error> { get }
    
    associatedtype ResponseType: Decodable
}
