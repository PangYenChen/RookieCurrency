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
        
        // act
        sut.getSupportedCurrency { result in receivedResult = result }
        do {
            let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
                .Instance
                .supportedSymbols()
            supportedCurrencyProvider.executeCompletionHandler(with: .success(supportedSymbols))
        }
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        do {
            let receivedResult: Result<[ResponseDataModel.CurrencyCode: String], any Error> = try XCTUnwrap(receivedResult)
            switch receivedResult {
                case .success(let supportedCurrency): XCTAssertFalse(supportedCurrency.isEmpty)
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
    
    func testTwoCallSiteSimultaneously() throws {
        // arrange
        var receivedFirstResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        var receivedSecondResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        
        // act
        sut.getSupportedCurrency { result in  receivedFirstResult = result }
        
        sut.getSupportedCurrency { result in receivedSecondResult = result }
        
        do {
            let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
                .Instance
                .supportedSymbols()
            supportedCurrencyProvider.executeCompletionHandler(with: .success(supportedSymbols))
        }
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do {
            let receivedFirstSupportedCurrency: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedFirstResult?.get())
            XCTAssertFalse(receivedFirstSupportedCurrency.isEmpty)
            
            let receivedSecondSupportedCurrency: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondResult?.get())
            XCTAssertFalse(receivedSecondSupportedCurrency.isEmpty)
            
            XCTAssertEqual(receivedFirstSupportedCurrency, receivedSecondSupportedCurrency)
        }
    }
    
    func testTwoCallSiteSequentially() throws {
        // arrange
        var receivedFirstResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        var receivedSecondResult: Result<[ResponseDataModel.CurrencyCode: String], Error>?
        
        // act
        sut.getSupportedCurrency { result in  receivedFirstResult = result }
        
        do {
            let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
                .Instance
                .supportedSymbols()
            supportedCurrencyProvider.executeCompletionHandler(with: .success(supportedSymbols))
        }
        
        sut.getSupportedCurrency { result in receivedSecondResult = result }
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do {
            let receivedFirstSupportedCurrency: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedFirstResult?.get())
            XCTAssertFalse(receivedFirstSupportedCurrency.isEmpty)
            
            let receivedSecondSupportedCurrency: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondResult?.get())
            XCTAssertFalse(receivedSecondSupportedCurrency.isEmpty)
            
            XCTAssertEqual(receivedFirstSupportedCurrency, receivedSecondSupportedCurrency)
        }
    }
}
