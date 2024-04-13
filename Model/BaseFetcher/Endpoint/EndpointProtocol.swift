import Foundation

protocol EndpointProtocol {
    var url: URL { get }
    
    associatedtype ResponseType: Decodable
}
