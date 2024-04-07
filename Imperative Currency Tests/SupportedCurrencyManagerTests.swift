import XCTest
@testable import ImperativeCurrency

final class SupportedCurrencyManagerTests: XCTestCase {
    var sut: SupportedCurrencyManager!
    
    var supportedCurrencyProvider: TestDouble.SupportedCurrencyProvider!

    override func setUp() {
        supportedCurrencyProvider = TestDouble.SupportedCurrencyProvider()
        
        sut = SupportedCurrencyManager(supportedCurrencyProvider: supportedCurrencyProvider)
    }

    override func tearDown() {
        sut = nil
        
        supportedCurrencyProvider = nil
    }
    
    func testSuccess() throws {
        // arrange
        var receivedResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        
        // act
        sut.getSupportedCurrency { result in receivedResult = result }
        do {
            let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
                .Instance
                .supportedSymbols()
            supportedCurrencyProvider.executeCompletionHandler(with: .success(supportedSymbols))
        }
        
        // assert
        do {
            let receivedResult: Result<[ResponseDataModel.CurrencyCode: String], any Error> = try XCTUnwrap(receivedResult)
            switch receivedResult {
                case .success(let supportedCurrency): XCTAssertFalse(supportedCurrency.isEmpty)
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
}
