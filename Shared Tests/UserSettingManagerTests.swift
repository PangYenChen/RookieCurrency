import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class UserSettingManagerTests: XCTestCase {
    private var sut: UserSettingManager!
    
    private var userDefaultsSpy: TestDouble.UserDefaults!
    
    override func setUp() {
        userDefaultsSpy = TestDouble.UserDefaults()
        sut = UserSettingManager(userDefaults: userDefaultsSpy)
    }
    
    override func tearDown() {
        sut = nil
        userDefaultsSpy = nil
    }
    
    // MARK: - test number of days
    func testDefaultValueOfNumberOfDays() {
        // arrange, do nothing
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.numberOfDays, sut.defaultNumberOfDays)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.numberOfDays.rawValue])
    }
    
    func testNumberOfDaysFallBackToDefaultValueWhenUserDefaultsValueIsIllegal() {
        // arrange
        userDefaultsSpy.set(-1, forKey: UserSettingManager.Key.numberOfDays.rawValue)
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.numberOfDays, sut.defaultNumberOfDays)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
    }
    
    func testNumberOfDaysDoNotStoreInDefaultValueAfterSettingSameValue() {
        // arrange, do nothing
        
        // act
        sut.numberOfDays = sut.defaultNumberOfDays
        
        // assert
        XCTAssertEqual(sut.numberOfDays, sut.defaultNumberOfDays)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.numberOfDays.rawValue])
    }
    
    func testNumberOfDaysStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange, do nothing
        let newNumberOfDays: Int = sut.defaultNumberOfDays + 1
        
        // act
        sut.numberOfDays = newNumberOfDays
        
        // assert
        XCTAssertEqual(sut.numberOfDays, newNumberOfDays)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
    }
    
    // MARK: - test base currency code
    func testDefaultValueOfBaseCurrencyCode() {
        // arrange, do nothing
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.baseCurrencyCode, sut.defaultBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.baseCurrencyCode.rawValue])
    }
    
    func testBaseCurrencyCodeFallBackToDefaultValueWhenUserDefaultsValueIsIllegal() {
        // arrange
        userDefaultsSpy.set("something illegal", forKey: UserSettingManager.Key.baseCurrencyCode.rawValue)
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.baseCurrencyCode, sut.defaultBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
    }
    
    func testBaseCurrencyCodeDoNotStoreInDefaultValueAfterSettingSameValue() {
        // arrange, do nothing
        
        // act
        sut.baseCurrencyCode = sut.defaultBaseCurrencyCode
        
        // assert
        XCTAssertEqual(sut.baseCurrencyCode, sut.defaultBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.baseCurrencyCode.rawValue])
    }
    
    func testBaseCurrencyCodeStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange, do nothing
        let newBaseCurrencyCode: ResponseDataModel.CurrencyCode = sut.defaultBaseCurrencyCode + "something to simulate setting different value"
        
        // act
        sut.baseCurrencyCode = newBaseCurrencyCode
        
        // assert
        XCTAssertEqual(sut.baseCurrencyCode, newBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
    }
    
    // MARK: - test currency code of interest
    func testDefaultValueOfCurrencyCodeOfInterest() {
        // arrange, do nothing
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.currencyCodeOfInterest, sut.defaultCurrencyCodeOfInterest)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue])
    }
    
    func testCurrencyCodeOfInterestFallBackToDefaultValueWhenUserDefaultsValueIsIllegal() {
        // arrange
        userDefaultsSpy.set("something illegal", forKey: UserSettingManager.Key.currencyCodeOfInterest.rawValue)
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.currencyCodeOfInterest, sut.defaultCurrencyCodeOfInterest)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
    }
    
    func testCurrencyCodeOfInterestDoNotStoreInDefaultValueAfterSettingSameValue() {
        // arrange, do nothing
        
        // act
        sut.currencyCodeOfInterest = sut.defaultCurrencyCodeOfInterest
        
        // assert
        XCTAssertEqual(sut.currencyCodeOfInterest, sut.defaultCurrencyCodeOfInterest)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue])
    }
    
    func testCurrencyCodeOfInterestStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange, do nothing
        let newCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["something to simulate setting different value"]
        
        // act
        sut.currencyCodeOfInterest = newCurrencyCodeOfInterest
        
        // assert
        XCTAssertEqual(sut.currencyCodeOfInterest, newCurrencyCodeOfInterest)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
    }
    
    // MARK: - test result order
    func testDefaultValueOfResultOrder() {
        // arrange, do nothing
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.resultOrder, sut.defaultResultOrder)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.resultOrder.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.resultOrder.rawValue])
    }
    
    func testResultOrderFallBackToDefaultValueWhenUserDefaultsValueIsIllegal() {
        // arrange
        userDefaultsSpy.set("something illegal", forKey: UserSettingManager.Key.resultOrder.rawValue)
        
        // act, do nothing
        
        // assert
        XCTAssertEqual(sut.resultOrder, sut.defaultResultOrder)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.resultOrder.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.resultOrder.rawValue], 1)
    }
    
    func testResultOrderDoNotStoreInDefaultValueAfterSettingSameValue() {
        // arrange, do nothing
        
        // act
        sut.resultOrder = sut.defaultResultOrder
        
        // assert
        XCTAssertEqual(sut.resultOrder, sut.defaultResultOrder)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.resultOrder.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.resultOrder.rawValue])
    }
    
    func testResultOrderStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange, do nothing
        let newResultOrder: BaseResultModel.Order = switch sut.defaultResultOrder {
            case .increasing: .decreasing
            case .decreasing: .increasing
        }
        
        // act
        sut.resultOrder = newResultOrder
        
        // assert
        XCTAssertEqual(sut.resultOrder, newResultOrder)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.resultOrder.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.resultOrder.rawValue], 1)
    }
}
