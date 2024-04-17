import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class KeyManagerTests: XCTestCase {
    private var sut: KeyManager!
    
    private var unusedAPIKeys: Set<String>!
    
    override func setUp() {
        unusedAPIKeys = Set((0..<100).map { _ in UUID().uuidString })
        
        sut = KeyManager(unusedAPIKeys: unusedAPIKeys)
    }
    
    override func tearDown() {
        sut = nil
        
        unusedAPIKeys = nil
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
    
    func testRunOutOfKeys() throws {
        // arrange, do nothing
        
        // act, do nothing
        
        // assert
        
        for _ in 0..<unusedAPIKeys.count {
            let usingAPIKey: String = try sut.usingAPIKeyResult.get()
            sut.deprecate(usingAPIKey)
        }
        
        XCTAssertThrowsError(try sut.usingAPIKeyResult.get())
    }
    
    func testDeprecatingSameAPIKey() throws {
        // arrange
        let firstAPIKey: String = try sut.usingAPIKeyResult.get()
        
        // act
        sut.deprecate(firstAPIKey)
        let secondAPIKey: String = try sut.usingAPIKeyResult.get()
        sut.deprecate(firstAPIKey)
        let thirdAPIKey: String = try sut.usingAPIKeyResult.get()
        
        // assert
        XCTAssertEqual(secondAPIKey, thirdAPIKey)
    }
    
    func testEmptyInitialUnusedKeys() {
        // arrange
        sut = KeyManager(unusedAPIKeys: [])
        
        // act, do nothing
        
        // assert
        switch sut.usingAPIKeyResult {
            case .success(let usingAPIKey): XCTFail("should not receive .success, but receive: \(usingAPIKey)")
            case .failure(let failure): XCTAssertEqual(failure as? KeyManager.Error, .runOutOfKey)
        }
    }
    
    
}
