import XCTest
@testable import ImperativeCurrency

final class SupportedCurrencyManagerTests: XCTestCase {
    private var sut: SupportedCurrencyManager!
    
    private var supportedCurrencyProvider: TestDouble.SupportedCurrencyProvider!
    private var serialDispatchQueue: DispatchQueue!

    override func setUp() {
        supportedCurrencyProvider = TestDouble.SupportedCurrencyProvider()
        serialDispatchQueue = DispatchQueue(label: "supported.currency.manager.test")
        
        sut = SupportedCurrencyManager(supportedCurrencyProvider: supportedCurrencyProvider,
                                       serialDispatchQueue: serialDispatchQueue)
    }

    override func tearDown() {
        sut = nil
        
        supportedCurrencyProvider = nil
        serialDispatchQueue = nil
    }
    
    func testSuccess() throws {
        // arrange
        var receivedResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.getSupportedCurrency { result in receivedResult = result }
        supportedCurrencyProvider.executeCompletionHandler(with: .success(supportedSymbols))
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        do {
            let receivedResult: Result<[ResponseDataModel.CurrencyCode: String], any Error> = try XCTUnwrap(receivedResult)
            switch receivedResult {
                case .success(let supportedCurrency): XCTAssertEqual(supportedCurrency, expectedValue)
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
    
    func testSecondCallBeforeFirstReturn() throws {
        // arrange
        var receivedSecondResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.prefetchSupportedCurrency()
        
        sut.getSupportedCurrency { result in receivedSecondResult = result }
        
        supportedCurrencyProvider.executeCompletionHandler(with: .success(supportedSymbols))
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert second result*/ {
            let receivedSecondSupportedCurrency: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondResult?.get())
            XCTAssertEqual(receivedSecondSupportedCurrency, expectedValue)
        }
    }
    
    func testTwoCallSiteSequentially() throws {
        // arrange
        var receivedSecondResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.prefetchSupportedCurrency()
        
        supportedCurrencyProvider.executeCompletionHandler(with: .success(supportedSymbols))
        
        sut.getSupportedCurrency { result in receivedSecondResult = result }
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert second result*/ {
            let receivedSecondSupportedCurrency: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondResult?.get())
            XCTAssertEqual(receivedSecondSupportedCurrency, expectedValue)
        }
    }
}
