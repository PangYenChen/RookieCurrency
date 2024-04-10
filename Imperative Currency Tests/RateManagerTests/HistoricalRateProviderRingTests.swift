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
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandlerDictionary[dummyDateString])
        
        // act
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        sut.historicalRateFor(dateString: dummyDateString) { rateResult in receivedRateResult = rateResult }
        
        XCTAssertNotNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandlerDictionary[dummyDateString])
        
        do {
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData
                .Instance
                .historicalRateFor(dateString: dummyDateString)
            nextHistoricalRateProvider.executeHistoricalRateResultHandlerFor(dateString: dummyDateString,
                                                                             with: .success(dummyHistoricalRate))
        }
        
        // assert
        XCTAssertNoThrow(try XCTUnwrap(receivedRateResult?.get()))
        
        XCTAssertNotNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandlerDictionary[dummyDateString])
        
        // arrange
        receivedRateResult = nil
        
        // act
        sut.historicalRateFor(dateString: dummyDateString) { rateResult in receivedRateResult = rateResult }
        
        // assert
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandlerDictionary[dummyDateString])
        
        XCTAssertNoThrow(try XCTUnwrap(receivedRateResult?.get()))
        
        // act
        sut.removeAllStorage()

        // assert
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
    }
    
    func testFailure() throws {
        // arrange
        var receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        let dummyDateString: String = "1970-01-01"
        let expectedURLTimeoutError: URLError = URLError(URLError.Code.timedOut)
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandlerDictionary[dummyDateString])
        
        // act
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        sut.historicalRateFor(dateString: dummyDateString) { rateResult in receivedRateResult = rateResult }
        
        XCTAssertNotNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandlerDictionary[dummyDateString])
        
        nextHistoricalRateProvider.executeHistoricalRateResultHandlerFor(dateString: dummyDateString,
                                                                         with: .failure(expectedURLTimeoutError))
        
        // assert
        do {
            let receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error> = try XCTUnwrap(receivedRateResult)
            switch receivedRateResult {
                case .success(let rate): XCTFail("should not receive a rate, but receive: \(rate)")
                case .failure(let error): XCTAssertEqual(error as? URLError, expectedURLTimeoutError)
            }
        }
        
        XCTAssertNil(historicalRateStorage.dateStringAndRateDirectory[dummyDateString])
        
        XCTAssertNil(nextHistoricalRateProvider.dateStringAndHistoricalRateResultHandlerDictionary[dummyDateString])
    }
}
