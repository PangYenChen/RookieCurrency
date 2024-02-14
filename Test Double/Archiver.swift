import Foundation

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    enum SpyArchiver: ArchiverProtocol {
        private(set) static var numberOfArchiveCall: Int = 0
        
        private(set) static var numberOfUnarchiveCall: Int = 0
        
        private static var archivedFileNames: [String] = []
        
        static func reset() {
            numberOfArchiveCall = 0
            numberOfUnarchiveCall = 0
            archivedFileNames = []
        }
        
        static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws {
            numberOfArchiveCall += 1
            
            archivedFileNames.append(historicalRate.dateString)
        }
        
        static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
            numberOfUnarchiveCall += 1
            
            return try TestingData.Instance.historicalRateFor(dateString: fileName)
        }
        
        static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool {
            archivedFileNames.contains(fileName)
        }
        
        static func removeAllStoredFile() throws {}
    }
}
