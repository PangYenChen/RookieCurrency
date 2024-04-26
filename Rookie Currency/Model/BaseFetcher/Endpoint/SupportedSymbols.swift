import Foundation

extension Endpoints {
    struct SupportedSymbols: PartialPathProvider {
        let partialPath: String = "/symbols"
        let description: String = "symbols endpoint"
        
        typealias ResponseType = ResponseDataModel.SupportedSymbols
    }
}
