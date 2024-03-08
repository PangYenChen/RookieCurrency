import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

/// 測試 archiver 的 test case
/// 我不太確定要怎麼測試，archiver 其實很薄。
final class ArchiverTest: XCTestCase {
    private let sut: Archiver.Type = Archiver.self
    
    /// 測試先存一個檔案，再讀出來，確認前後一致。
    /// 我知道這樣不好，應該要抽換掉 `Data` 之類的 dependency，
    /// 但是把 `Data` 包一層又怪怪的。
    func testArchiveAndThenUnarchive() throws {
        // arrange
        let dummyDateString: String = "1970-01-01"
        let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        
        // act
        try sut.archive(historicalRate: dummyHistoricalRate)
        let unarchivedHistoricalRate: ResponseDataModel.HistoricalRate = try sut.unarchive(historicalRateDateString: dummyHistoricalRate.dateString)
        
        // assert
        XCTAssertEqual(dummyHistoricalRate, unarchivedHistoricalRate)
    }
}
