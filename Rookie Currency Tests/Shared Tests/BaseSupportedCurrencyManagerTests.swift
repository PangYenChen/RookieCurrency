import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class BaseSupportedCurrencyManagerTests: XCTestCase {
    private var sut: BaseSupportedCurrencyManager!
    
    private var locale: Locale!
    private var dummySupportedCurrencyProvider: SupportedCurrencyProviderProtocol!
    private var dummyDispatchQueue: DispatchQueue!
    
    override func setUp() {
        locale = Locale(identifier: "en")
        dummySupportedCurrencyProvider = TestDouble.SupportedCurrencyProvider()
        dummyDispatchQueue = DispatchQueue(label: "base.supported.currency.manager")
        
        sut = BaseSupportedCurrencyManager(supportedCurrencyProvider: dummySupportedCurrencyProvider,
                                           locale: locale,
                                           internalSerialDispatchQueue: dummyDispatchQueue)
    }
    
    override func tearDown() {
        sut = nil
        
        locale = nil
        dummySupportedCurrencyProvider = nil
        dummyDispatchQueue = nil
    }
    
    func testDescriptionFromLocale() {
        // arrange
        let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "USD"
        let expectedDescription: String = "US Dollar" // this is from documentation
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.localizedStringFor(currencyCode: dummyCurrencyCode),
                       expectedDescription)
    }
    
    func testDescriptionFromServer() {
        // arrange
        let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "something not in ISO 4217"
        let expectedDescription: String = UUID().uuidString
        let serverDescription: BaseSupportedCurrencyManager.CurrencyCodeDescriptions = [dummyCurrencyCode: expectedDescription]
        
        sut.cachedValue = serverDescription
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.localizedStringFor(currencyCode: dummyCurrencyCode),
                       expectedDescription)
    }
    
    func testDescriptionFallback() {
        // arrange
        let dummyCurrencyCode: ResponseDataModel.CurrencyCode = "something not in ISO 4217"
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.localizedStringFor(currencyCode: dummyCurrencyCode),
                       dummyCurrencyCode)
    }
}
