import XCTest
import Combine
@testable import ReactiveCurrency

final class SupportedCurrencyManagerTests: XCTestCase {
    private var sut: SupportedCurrencyManager!
    
    private var supportedCurrencyProvider: TestDouble.SupportedCurrencyProvider!
    private var serialDispatchQueue: DispatchQueue!
    
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        supportedCurrencyProvider = TestDouble.SupportedCurrencyProvider()
        serialDispatchQueue = DispatchQueue(label: "supported.currency.manager.test")
        
        sut = SupportedCurrencyManager(supportedCurrencyProvider: supportedCurrencyProvider,
                                       serialDispatchQueue: serialDispatchQueue)
        
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        sut = nil
        
        supportedCurrencyProvider = nil
        serialDispatchQueue = nil
    }
    
    func testSuccess() throws {
        // arrange
        var receivedValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { value in receivedValue = value })
            .store(in: &anyCancellableSet)

        supportedCurrencyProvider.publish(supportedSymbols)
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        do /*assert about receivedValue*/ {
            let receivedValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedValue)
            XCTAssertEqual(receivedValue, expectedValue)
        }
        
        do /*assert about receivedCompletion*/ {
            var receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
    
    func testTwoCallSiteSimultaneously() throws {
        // arrange
        var receivedFirstValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedFirstCompletion: Subscribers.Completion<Error>?
        
        var receivedSecondValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedSecondCompletion: Subscribers.Completion<Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedFirstCompletion = completion },
                  receiveValue: { value in receivedFirstValue = value })
            .store(in: &anyCancellableSet)
            
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedSecondCompletion = completion },
                  receiveValue: { value in receivedSecondValue = value })
            .store(in: &anyCancellableSet)
        
        supportedCurrencyProvider.publish(supportedSymbols)
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert first subscribers*/ {
            let receivedFirstValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedFirstValue)
            XCTAssertEqual(receivedFirstValue, expectedValue)
            
            var receivedFirstCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedFirstCompletion)
            switch receivedFirstCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
        
        do /*assert second subscriber*/ {
            let receivedSecondValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondValue)
            XCTAssertEqual(receivedSecondValue, expectedValue)
            
            var receivedSecondCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedSecondCompletion)
            switch receivedSecondCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
    
    func testTwoCallSiteSequentially() throws {
        // arrange
        var receivedFirstValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedFirstCompletion: Subscribers.Completion<Error>?
        
        var receivedSecondValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedSecondCompletion: Subscribers.Completion<Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedFirstCompletion = completion },
                  receiveValue: { value in receivedFirstValue = value })
            .store(in: &anyCancellableSet)
        
        supportedCurrencyProvider.publish(supportedSymbols)
        
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedSecondCompletion = completion },
                  receiveValue: { value in receivedSecondValue = value })
            .store(in: &anyCancellableSet)
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert first subscribers*/ {
            let receivedFirstValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedFirstValue)
            XCTAssertEqual(receivedFirstValue, expectedValue)
            
            var receivedFirstCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedFirstCompletion)
            switch receivedFirstCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
        
        do /*assert second subscriber*/ {
            let receivedSecondValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondValue)
            XCTAssertEqual(receivedSecondValue, expectedValue)
            
            var receivedSecondCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedSecondCompletion)
            switch receivedSecondCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
}
