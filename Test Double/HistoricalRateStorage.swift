#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    class HistoricalRateStorage: HistoricalRateStorageProtocol {
        init() {
            dateStringAndRateDirectory = [:]
        }
        
        private(set) var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate]
        
        func readFor(dateString: String) -> ResponseDataModel.HistoricalRate? {
            dateStringAndRateDirectory[dateString]
        }
        
        func store(_ rate: ResponseDataModel.HistoricalRate) {
            dateStringAndRateDirectory[rate.dateString] = rate
        }
        
        func removeAll() {
            dateStringAndRateDirectory.removeAll()
        }
    }
}
