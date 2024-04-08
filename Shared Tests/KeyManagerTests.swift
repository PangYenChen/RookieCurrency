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
    
    private var concurrentDispatchQueue: DispatchQueue!
    private var unusedAPIKeys: Set<String>!
    
    override func setUp() {
        concurrentDispatchQueue = DispatchQueue(label: "key.manager.tests", attributes: .concurrent)
        unusedAPIKeys = Set((0..<100).map { _ in UUID().uuidString })
        
        sut = KeyManager(concurrentDispatchQueue: concurrentDispatchQueue,
                         unusedAPIKeys: unusedAPIKeys)
    }
    
    override func tearDown() {
        sut = nil
        
        unusedAPIKeys = nil
        concurrentDispatchQueue = nil
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
        var usingAPIKey: String = try sut.getUsingAPIKey().get()
        
        for _ in 0..<(unusedAPIKeys.count - 1) {
            usingAPIKey = try sut.getUsingAPIKeyAfterDeprecating(usingAPIKey).get()
        }
        
        XCTAssertThrowsError(try sut.getUsingAPIKeyAfterDeprecating(usingAPIKey).get())
        XCTAssertThrowsError(try sut.getUsingAPIKey().get())
    }
    
    func testRunOutOfKeysConcurrently() throws {
        // arrange
        let concurrentDispatchQueue: DispatchQueue = DispatchQueue(label: "test.run.out.of.keys.concurrently",
                                                                   attributes: .concurrent)
        // act
        for _ in 0..<(unusedAPIKeys.count - 1) {
            concurrentDispatchQueue.async { [unowned self] in
                switch sut.getUsingAPIKey() {
                    case .success(let usingAPIKey):
                        switch sut.getUsingAPIKeyAfterDeprecating(usingAPIKey) {
                            case .success: break
                            case .failure: XCTFail("api key的數量應該夠多，即使拿到的對象不對，至少能拿到東西")
                        }
                        
                    case .failure:
                        XCTFail("api key的數量應該夠多，即使拿到的對象不對，至少能拿到東西")
                }
            }
        }
        
        concurrentDispatchQueue.sync(flags: .barrier) { /*intentionally left blank*/ }
        
        // assert, should not crash
    }
    
    func testDeprecatingSameAPIKey() throws {
        // arrange
        let usingAPIKey: String = try sut.getUsingAPIKey().get()
        let concurrentDispatchQueue: DispatchQueue = DispatchQueue(label: "test.deprecating.same.api.key",
                                                                   attributes: .concurrent)
        
        let newUsingAPIKey: String = try sut.getUsingAPIKeyAfterDeprecating(usingAPIKey).get()
        
        // act
        for _ in 0..<(unusedAPIKeys.count / 2) {
            concurrentDispatchQueue.async { [unowned self] in sut.getUsingAPIKeyAfterDeprecating(usingAPIKey) }
        }
        
        concurrentDispatchQueue.sync(flags: .barrier) { /*intentionally left blank*/ }
        
        // assert
        let currentUsingAPIKey: String = try sut.getUsingAPIKey().get()
        XCTAssertEqual(newUsingAPIKey, currentUsingAPIKey)
    }
}
