import XCTest
@testable import ImperativeCurrency

class HistoricalRateProviderRingTests: XCTestCase {
    private var sut: HistoricalRateProviderRing!
    
    private var historicalRateStorage: TestDouble.HistoricalRateStorage!
    private var nextHistoricalRateProvider: TestDouble.HistoricalRateProvider!
    
    override func setUp() {
        historicalRateStorage = TestDouble.HistoricalRateStorage(dateStringAndRateDirectory: [:])
        nextHistoricalRateProvider = TestDouble.HistoricalRateProvider()
        
        sut = HistoricalRateProviderRing(storage: historicalRateStorage,
                                         nextProvider: nextHistoricalRateProvider)
    }
    
    override func tearDown() {
        sut = nil
        
        historicalRateStorage = nil
        nextHistoricalRateProvider = nil
    }
    
    func testNoRetainCycleOccur() {
        // arrange
        addTeardownBlock { [weak sut] in
            // assert
            XCTAssertNil(sut)
        }
        // act
        sut = nil
    }
    
    func testGetFromNextProviderAndThenGetFromStorageAndThenRemoveAllStorage() throws {
        // arrange
        var receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        let dummyDateString: String = "1970-01-01"
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandler[dummyDateString])
        
        // act
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        sut.historicalRateFor(dateString: dummyDateString) { rateResult in receivedRateResult = rateResult }
        
        XCTAssertNotNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandler[dummyDateString])
        
        do {
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData
                .Instance
                .historicalRateFor(dateString: dummyDateString)
            nextHistoricalRateProvider.executeHistoricalRateResultHandlerFor(dateString: dummyDateString,
                                                                             with: .success(dummyHistoricalRate))
        }
        
        // assert
        try XCTUnwrap(receivedRateResult?.get())
        
        XCTAssertNotNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandler[dummyDateString])
        
        // arrange
        receivedRateResult = nil
        
        // act
        sut.historicalRateFor(dateString: dummyDateString) { rateResult in receivedRateResult = rateResult }
        
        // assert
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandler[dummyDateString])
        
        try XCTUnwrap(receivedRateResult?.get())
        
        // act
        sut.removeAllStorage()

        // assert
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
    }
    
    func testFailure() {
        // arrange
        var receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        let dummyDateString: String = "1970-01-01"
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandler[dummyDateString])
        
        // act
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        sut.historicalRateFor(dateString: dummyDateString) { rateResult in receivedRateResult = rateResult }
        
        XCTAssertNotNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandler[dummyDateString])
        
        do {
            let dummyError: URLError = URLError(URLError.Code.timedOut)
            nextHistoricalRateProvider.executeHistoricalRateResultHandlerFor(dateString: dummyDateString,
                                                                             with: .failure(dummyError))
        }
        
        // assert
        try XCTAssertThrowsError(receivedRateResult?.get())
        
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
    }
}
