import XCTest
@testable import ImperativeCurrency

class HistoricalRateProviderTests: XCTestCase {
    private var sut: HistoricalRateProvider!
    
    private var historicalRateProviderSpy: TestDouble.HistoricalRateProvider!
    
    override func setUp() {
        historicalRateProviderSpy = TestDouble.HistoricalRateProvider()
        
        sut = HistoricalRateProvider(nextHistoricalRateProvider: historicalRateProviderSpy)
    }
    
    override func tearDown() {
        sut = nil
        
        historicalRateProviderSpy = nil
    }
    
    func testPassingSuccess() throws {
        // arrange
        var receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        let dateString: String = "1970-01-01"
        let expectedRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dateString)
        
        sut.rateFor(dateString: dateString) { historicalRateResult in receivedRateResult = historicalRateResult }
        
        // act
        historicalRateProviderSpy.executeHistoricalRateResultHandlerFor(dateString: dateString,
                                                                         with: .success(expectedRate))
        
        // assert
        do {
            let receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error> = try XCTUnwrap(receivedRateResult)
            switch receivedRateResult {
                case .success(let receivedRate): XCTAssertEqual(receivedRate, expectedRate)
                case .failure(let receivedFailure): XCTFail("should not receive failure, but receive: \(receivedFailure)")
            }
        }
    }
    
    func testPassingFailure() throws {
        // arrange
        var receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error>?
        let dateString: String = "1970-01-01"
        let expectedTimeOut: URLError = URLError(URLError.Code.timedOut)
        
        sut.rateFor(dateString: dateString) { historicalRateResult in receivedRateResult = historicalRateResult }
        
        // act
        historicalRateProviderSpy.executeHistoricalRateResultHandlerFor(dateString: dateString,
                                                                         with: .failure(expectedTimeOut))
        
        // assert
        do {
            let receivedRateResult: Result<ResponseDataModel.HistoricalRate, Error> = try XCTUnwrap(receivedRateResult)
            switch receivedRateResult {
                case .success(let receivedRate): XCTFail("should not receive output, but receive: \(receivedRate)")
                case .failure(let receivedFailure): XCTAssertEqual(receivedFailure as? URLError, expectedTimeOut)
            }
        }
    }
}
