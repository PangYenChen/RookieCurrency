import Foundation
@testable import ImperativeCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        func historicalRateFor(dateString: String, 
                               historicalRateHandler: @escaping HistoricalRateHandler) {
        }
    }
}
