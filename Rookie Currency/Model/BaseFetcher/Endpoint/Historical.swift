import Foundation

extension Endpoints {
    struct Historical: BaseOnTWD {
        init(dateString: String) {
            partialPath = "/" + dateString
            description = "historical endpoint with date: \(dateString)"
        }
        
        let partialPath: String
        let description: String
        
        typealias ResponseType = ResponseDataModel.HistoricalRate
    }
}
