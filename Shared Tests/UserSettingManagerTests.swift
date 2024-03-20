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
    
    // TODO: 測 retain cycle
    
    // MARK: - test number of days
    func testDefaultValueOfNumberOfDays() {
        // arrange, do nothing. UserDefaults spy is initially empty.
        
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
    
    func testNumberOfDaysDoNotStoreInDefaultValueAfterSettingSameValueUsingDefaultValue() {
        // arrange, do nothing
        
        // act
        sut.numberOfDays = sut.defaultNumberOfDays
        
        // assert
        XCTAssertEqual(sut.numberOfDays, sut.defaultNumberOfDays)
        XCTAssertNil(userDefaultsSpy.dataDictionary[UserSettingManager.Key.numberOfDays.rawValue])
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.numberOfDays.rawValue])
    }
    
    func testNumberOfDaysStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange
        let newNumberOfDays: Int = sut.defaultNumberOfDays + 1
        
        // act
        sut.numberOfDays = newNumberOfDays
        
        // assert
        XCTAssertEqual(sut.numberOfDays, newNumberOfDays)
        XCTAssertEqual(userDefaultsSpy.dataDictionary[UserSettingManager.Key.numberOfDays.rawValue] as? Int, newNumberOfDays)
        
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
    }
    
    func testNumberOfDaysDoNotStoreInDefaultValueAfterSettingSameValueUsingNewValue() {
        // arrange
        let newNumberOfDays: Int = sut.defaultNumberOfDays + 1
        
        // act
        sut.numberOfDays = newNumberOfDays
        sut.numberOfDays = newNumberOfDays
        
        // assert
        XCTAssertEqual(sut.numberOfDays, newNumberOfDays)
        XCTAssertEqual(userDefaultsSpy.dataDictionary[UserSettingManager.Key.numberOfDays.rawValue] as? Int, newNumberOfDays)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.numberOfDays.rawValue], 1)
    }
    
    // MARK: - test base currency code
    func testDefaultValueOfBaseCurrencyCode() {
        // arrange, do nothing. UserDefaults spy is initially empty.
        
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
    
    func testBaseCurrencyCodeDoNotStoreInDefaultValueAfterSettingSameValueUsingDefaultValue() {
        // arrange, do nothing
        
        // act
        sut.baseCurrencyCode = sut.defaultBaseCurrencyCode
        
        // assert
        XCTAssertEqual(sut.baseCurrencyCode, sut.defaultBaseCurrencyCode)
        XCTAssertNil(userDefaultsSpy.dataDictionary[UserSettingManager.Key.baseCurrencyCode.rawValue])
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.baseCurrencyCode.rawValue])
    }
    
    func testBaseCurrencyCodeStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange
        let newBaseCurrencyCode: ResponseDataModel.CurrencyCode = sut.defaultBaseCurrencyCode + "something to simulate setting different value"
        
        // act
        sut.baseCurrencyCode = newBaseCurrencyCode
        
        // assert
        XCTAssertEqual(sut.baseCurrencyCode, newBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.dataDictionary[UserSettingManager.Key.baseCurrencyCode.rawValue] as? String,
                       newBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
    }
    
    func testBaseCurrencyCodeDoNotStoreInDefaultValueAfterSettingSameValueUsingNewValue() {
        // arrange
        let newBaseCurrencyCode: ResponseDataModel.CurrencyCode = sut.defaultBaseCurrencyCode + "something to simulate setting different value"
        
        // act
        sut.baseCurrencyCode = newBaseCurrencyCode
        sut.baseCurrencyCode = newBaseCurrencyCode
        
        // assert
        XCTAssertEqual(sut.baseCurrencyCode, newBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.dataDictionary[UserSettingManager.Key.baseCurrencyCode.rawValue] as? String,
                       newBaseCurrencyCode)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.baseCurrencyCode.rawValue], 1)
    }
    
    // MARK: - test currency code of interest
    func testDefaultValueOfCurrencyCodeOfInterest() {
        // arrange, do nothing. UserDefaults spy is initially empty.
        
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
    
    func testCurrencyCodeOfInterestDoNotStoreInDefaultValueAfterSettingSameValueUsingDefaultValue() {
        // arrange, do nothing
        
        // act
        sut.currencyCodeOfInterest = sut.defaultCurrencyCodeOfInterest
        
        // assert
        XCTAssertEqual(sut.currencyCodeOfInterest, sut.defaultCurrencyCodeOfInterest)
        XCTAssertNil(userDefaultsSpy.dataDictionary[UserSettingManager.Key.currencyCodeOfInterest.rawValue])
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue])
    }
    
    func testCurrencyCodeOfInterestStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange
        let newCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["something to simulate setting different value"]
        
        // act
        sut.currencyCodeOfInterest = newCurrencyCodeOfInterest
        
        // assert
        XCTAssertEqual(sut.currencyCodeOfInterest, newCurrencyCodeOfInterest)
        
        do {
            let arrayInSpy: [ResponseDataModel.CurrencyCode]? = userDefaultsSpy.dataDictionary[UserSettingManager.Key.currencyCodeOfInterest.rawValue] as? [String]
            XCTAssertEqual(arrayInSpy.map(Set.init),
                           newCurrencyCodeOfInterest)
        }
        
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
    }
    
    func testCurrencyCodeOfInterestDoNotStoreInDefaultValueAfterSettingSameValueUsingNewValue() {
        // arrange
        let newCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["something to simulate setting different value"]
        
        // act
        sut.currencyCodeOfInterest = newCurrencyCodeOfInterest
        sut.currencyCodeOfInterest = newCurrencyCodeOfInterest
        
        // assert
        XCTAssertEqual(sut.currencyCodeOfInterest, newCurrencyCodeOfInterest)
        
        do {
            let arrayInSpy: [ResponseDataModel.CurrencyCode]? = userDefaultsSpy.dataDictionary[UserSettingManager.Key.currencyCodeOfInterest.rawValue] as? [String]
            XCTAssertEqual(arrayInSpy.map(Set.init),
                           newCurrencyCodeOfInterest)
        }
        
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.currencyCodeOfInterest.rawValue], 1)
    }
    
    // MARK: - test result order
    func testDefaultValueOfResultOrder() {
        // arrange, do nothing. UserDefaults spy is initially empty.
        
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
    
    func testResultOrderDoNotStoreInDefaultValueAfterSettingSameValueUsingDefaultValue() {
        // arrange, do nothing
        
        // act
        sut.resultOrder = sut.defaultResultOrder
        
        // assert
        XCTAssertEqual(sut.resultOrder, sut.defaultResultOrder)
        XCTAssertNil(userDefaultsSpy.dataDictionary[UserSettingManager.Key.resultOrder.rawValue])
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.resultOrder.rawValue], 1)
        XCTAssertNil(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.resultOrder.rawValue])
    }
    
    func testResultOrderStoreInDefaultValueAfterSettingDifferentValue() {
        // arrange
        let newResultOrder: BaseResultModel.Order = switch sut.defaultResultOrder {
            case .increasing: .decreasing
            case .decreasing: .increasing
        }
        
        // act
        sut.resultOrder = newResultOrder
        
        // assert
        XCTAssertEqual(sut.resultOrder, newResultOrder)
        XCTAssertEqual(userDefaultsSpy.dataDictionary[UserSettingManager.Key.resultOrder.rawValue] as? String,
                       newResultOrder.rawValue)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.resultOrder.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.resultOrder.rawValue], 1)
    }
    
    func testResultOrderDoNotStoreInDefaultValueAfterSettingSameValueUsingNewValue() {
        // arrange
        let newResultOrder: BaseResultModel.Order = switch sut.defaultResultOrder {
            case .increasing: .decreasing
            case .decreasing: .increasing
        }
        
        // act
        sut.resultOrder = newResultOrder
        sut.resultOrder = newResultOrder
        
        // assert
        XCTAssertEqual(sut.resultOrder, newResultOrder)
        XCTAssertEqual(userDefaultsSpy.dataDictionary[UserSettingManager.Key.resultOrder.rawValue] as? String,
                       newResultOrder.rawValue)
        XCTAssertEqual(userDefaultsSpy.numberOfUnarchive[UserSettingManager.Key.resultOrder.rawValue], 1)
        XCTAssertEqual(userDefaultsSpy.numberOfArchive[UserSettingManager.Key.resultOrder.rawValue], 1)
    }
}
