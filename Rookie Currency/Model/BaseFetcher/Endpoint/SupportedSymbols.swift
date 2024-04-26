import Foundation

extension Endpoints {
    struct SupportedSymbols: PartialPathProvider {
        typealias ResponseType = ResponseDataModel.SupportedSymbols
        
        let partialPath: String = "/symbols"
    }
}
