import Foundation

extension Endpoints {
    struct Latest: BaseOnTWD {
        typealias ResponseType = ResponseDataModel.LatestRate
        
        let partialPath: String = "/latest"
    }
}
