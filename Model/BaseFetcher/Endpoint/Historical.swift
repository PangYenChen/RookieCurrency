import Foundation

extension Endpoints {
    struct Historical: BaseOnTWD {
        typealias ResponseType = ResponseDataModel.HistoricalRate
        
        let partialPath: String
        
        init(dateString: String) {
            self.partialPath = dateString
        }
    }
}
