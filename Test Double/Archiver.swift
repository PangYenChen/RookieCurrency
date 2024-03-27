import Foundation

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    class Archiver: ArchiverProtocol {
        // MARK: - initializer
        init() {
            numberOfArchiveCall = 0
            numberOfUnarchiveCall = 0
            archivedFileNames = []
        }
        
        // MARK: - properties
        private(set) var numberOfArchiveCall: Int = 0
        private(set) var numberOfUnarchiveCall: Int = 0
        private var archivedFileNames: [String] = []
    }
}

extension TestDouble.Archiver {
    func archive(historicalRate: ResponseDataModel.HistoricalRate) throws {
        numberOfArchiveCall += 1
        
        archivedFileNames.append(historicalRate.dateString)
    }
    
    func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
        numberOfUnarchiveCall += 1
        
        return try TestingData.Instance.historicalRateFor(dateString: fileName)
    }
    
    func hasFileInDisk(historicalRateDateString fileName: String) -> Bool {
        archivedFileNames.contains(fileName)
    }
    
    func removeAllStoredFile() throws {}
}
