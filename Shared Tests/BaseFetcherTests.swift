import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class BaseFetcherTests: XCTestCase {
    private var sut: BaseFetcher!
    
    private var keyManager: KeyManager!
    private var currencySession: TestDouble.CurrencySession!
    
    override func setUp() {
        keyManager = KeyManager(unusedAPIKeys: [""])
        currencySession = TestDouble.CurrencySession()
        
        sut = BaseFetcher(keyManager: keyManager,
                          currencySession: currencySession)
    }
    
    override func tearDown() {
        sut = nil
        
        currencySession = nil
        keyManager = nil
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
    
    func testVenderResultSuccess() throws {
        // arrange
        let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
            .CurrencySessionTuple
            .latestRate()
        let data: Data = try XCTUnwrap(tuple.data)
        let urlResponse: URLResponse = try XCTUnwrap(tuple.response)
        
        // act
        let result: Result<Data, BaseFetcher.Error> = sut.venderResultFor(data: data, urlResponse: urlResponse)
        
        // assert
        XCTAssertEqual(result, .success(data))
    }
    
    func testVenderResultInvalidAPIKey() throws {
        // arrange
        let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
            .CurrencySessionTuple
            .invalidAPIKey()
        let data: Data = try XCTUnwrap(tuple.data)
        let urlResponse: URLResponse = try XCTUnwrap(tuple.response)
        
        // act
        let result: Result<Data, BaseFetcher.Error> = sut.venderResultFor(data: data, urlResponse: urlResponse)
        
        // assert
        XCTAssertEqual(result, .failure(BaseFetcher.Error.invalidAPIKey))
    }
    
    func testVenderResultRunOutOfQuota() throws {
        // arrange
        let tuple: (data: Data?, response: URLResponse?, error: Error?) = try TestingData
            .CurrencySessionTuple
            .tooManyRequest()
        let data: Data = try XCTUnwrap(tuple.data)
        let urlResponse: URLResponse = try XCTUnwrap(tuple.response)
        
        // act
        let result: Result<Data, BaseFetcher.Error> = sut.venderResultFor(data: data, urlResponse: urlResponse)
        
        // assert
        XCTAssertEqual(result, .failure(BaseFetcher.Error.runOutOfQuota))
    }
    
    func testVenderResultUnknownError() throws {
        // arrange
        let data: Data = Data()
        let urlResponse: URLResponse = try { () -> URLResponse in
            let dummyURL: URL = try XCTUnwrap(URL(string: "https://www.apple.com"))
            return URLResponse(url: dummyURL,
                               mimeType: nil,
                               expectedContentLength: 0,
                               textEncodingName: nil)
        }()
        
        // act
        let result: Result<Data, BaseFetcher.Error> = sut.venderResultFor(data: data, urlResponse: urlResponse)
        
        // assert
        XCTAssertEqual(result, .failure(BaseFetcher.Error.unknownError))
    }
}
