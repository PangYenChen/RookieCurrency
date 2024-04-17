import XCTest
#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class HistoricalRateCacheTests: XCTestCase {
    func testAll() throws {
        // arrange
        let sut: HistoricalRateCache = HistoricalRateCache()
        let dummyDateString: String = "1970-01-01"
        
        // act, do nothing
        
        // assert
        XCTAssertNil(sut.readFor(dateString: dummyDateString))
        
        // arrange
        let dummyRate: ResponseDataModel.HistoricalRate = try TestingData
            .Instance
            .historicalRateFor(dateString: dummyDateString)
        
        // act
        sut.store(dummyRate)
        
        // assert
        XCTAssertEqual(sut.readFor(dateString: dummyDateString),
                       dummyRate)
        
        // act
        sut.removeAll()
        
        // assert
        XCTAssertNil(sut.readFor(dateString: dummyDateString))
    }
}
