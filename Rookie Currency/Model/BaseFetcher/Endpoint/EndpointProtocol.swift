import Foundation

protocol EndpointProtocol: CustomStringConvertible {
    var urlResult: Result<URL, Error> { get }
    
    associatedtype ResponseType: Decodable
}
