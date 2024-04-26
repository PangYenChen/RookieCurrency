import Foundation

extension Endpoints {
    struct Latest: BaseOnTWD {
        let partialPath: String = "/latest"
        let description: String = "latest endpoint"
        
        typealias ResponseType = ResponseDataModel.LatestRate
    }
}
