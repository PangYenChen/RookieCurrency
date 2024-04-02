import XCTest
import Combine

@testable import ReactiveCurrency

final class SettingModelTests: XCTestCase {
    private var sut: SettingModel!
    
    private var dummySetting: BaseResultModel.Setting!
    private var saveSettingSubject: PassthroughSubject<BaseResultModel.Setting, Never>!
    private var cancelSubject: PassthroughSubject<Void, Never>!
    private var dummyCurrencyDescriber: CurrencyDescriberProtocol!
    
    private var anyCancellableSet: Set<AnyCancellable>!

    override func setUp() {
        dummySetting = (numberOfDays: 3,
                   baseCurrencyCode: "TWD",
                   currencyCodeOfInterest: ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"])
        saveSettingSubject = PassthroughSubject<BaseResultModel.Setting, Never>()
        cancelSubject = PassthroughSubject<Void, Never>()
        dummyCurrencyDescriber = TestDouble.CurrencyDescriber()
        
        sut = SettingModel(setting: dummySetting,
                           saveSettingSubscriber: AnySubscriber(saveSettingSubject),
                           cancelSubscriber: AnySubscriber(cancelSubject),
                           currencyDescriber: dummyCurrencyDescriber)
        
        anyCancellableSet = Set<AnyCancellable>()
    }

    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        sut = nil
        
        dummyCurrencyDescriber = nil
        cancelSubject = nil
        saveSettingSubject = nil
        dummySetting = nil
    }

    func testNumberOfDaysChanges() throws {
        // arrange
        var receivedHasModificationsToSave: Bool?
        var receivedNumberOfDaysDidChange: Void?
        
        sut.numberOfDaysDidChange
            .sink { numberOfDaysDidChange in receivedNumberOfDaysDidChange = numberOfDaysDidChange }
            .store(in: &anyCancellableSet)
        
        sut.hasModificationsToSave
            .sink { modificationsToSave in receivedHasModificationsToSave = modificationsToSave }
            .store(in: &anyCancellableSet)
        
        // act
        sut.set(numberOfDays: 4)
        
        // assert
        do /*assert about received has modifications to save*/ {
            let receivedHasModificationsToSave: Bool = try XCTUnwrap(receivedHasModificationsToSave)
            XCTAssert(receivedHasModificationsToSave)
        }
        XCTAssertEqual(sut.numberOfDays, 4)
        XCTAssertNotNil(receivedNumberOfDaysDidChange)
        
        // arrange
        receivedHasModificationsToSave = nil
        receivedNumberOfDaysDidChange = nil
        
        // act
        sut.set(numberOfDays: 3)
        
        // assert
        do /*assert about received has modifications to save*/ {
            let receivedHasModificationsToSave: Bool = try XCTUnwrap(receivedHasModificationsToSave)
            XCTAssertFalse(receivedHasModificationsToSave)
        }
        XCTAssertEqual(sut.numberOfDays, 3)
        XCTAssertNotNil(receivedNumberOfDaysDidChange)
    }

    func testSave() throws {
        // arrange
        var receivedSetting: BaseResultModel.Setting?
        var receivedCancel: Void?
        let expectedNumberOfDays: Int = 4
        
        saveSettingSubject
            .sink { setting in receivedSetting = setting }
            .store(in: &anyCancellableSet)
        
        cancelSubject
            .sink { cancel in receivedCancel = cancel }
            .store(in: &anyCancellableSet)
        
        // act
        sut.set(numberOfDays: expectedNumberOfDays)
        sut.save()
        
        // assert
        do /*assert about received setting*/ {
            let receivedSetting: BaseResultModel.Setting = try XCTUnwrap(receivedSetting)
            XCTAssertEqual(receivedSetting.numberOfDays, expectedNumberOfDays)
        }
        XCTAssertNil(receivedCancel)
    }
    
    func testCancelWithoutModificationToSave() throws {
        // arrange
        var receivedSetting: BaseResultModel.Setting?
        var receivedCancellationNeedsToBeConfirmed: Bool?
        var receivedCancel: Void?
        
        saveSettingSubject
            .sink { setting in receivedSetting = setting }
            .store(in: &anyCancellableSet)
        
        sut.cancellationNeedsToBeConfirmed
            .sink { cancellationNeedsToBeConfirmed in receivedCancellationNeedsToBeConfirmed = cancellationNeedsToBeConfirmed }
            .store(in: &anyCancellableSet)
        
        cancelSubject
            .sink { cancel in receivedCancel = cancel }
            .store(in: &anyCancellableSet)
        
        // act
        sut.attemptToCancel()
        
        // assert
        XCTAssertNil(receivedSetting)
        do /*assert about received cancellation needs to be confirmed*/ {
            let receivedCancellationNeedsToBeConfirmed: Bool = try XCTUnwrap(receivedCancellationNeedsToBeConfirmed)
            XCTAssertFalse(receivedCancellationNeedsToBeConfirmed)
        }
        XCTAssertNil(receivedCancel)
        
        // act
        receivedCancellationNeedsToBeConfirmed = nil
        sut.cancel()
        
        // assert
        XCTAssertNil(receivedSetting)
        XCTAssertNil(receivedCancellationNeedsToBeConfirmed)
        XCTAssertNotNil(receivedCancel)
    }
    
    func testCancelWithModificationToSave() throws {
        // arrange
        var receivedSetting: BaseResultModel.Setting?
        var receivedCancellationNeedsToBeConfirmed: Bool?
        var receivedCancel: Void?
        
        saveSettingSubject
            .sink { setting in receivedSetting = setting }
            .store(in: &anyCancellableSet)
        
        sut.cancellationNeedsToBeConfirmed
            .sink { cancellationNeedsToBeConfirmed in receivedCancellationNeedsToBeConfirmed = cancellationNeedsToBeConfirmed }
            .store(in: &anyCancellableSet)
        
        cancelSubject
            .sink { cancel in receivedCancel = cancel }
            .store(in: &anyCancellableSet)
        
        // act
        sut.set(numberOfDays: 4)
        sut.attemptToCancel()
        
        // assert
        XCTAssertNil(receivedSetting)
        do /*assert about received cancellation needs to be confirmed*/ {
            let receivedCancellationNeedsToBeConfirmed: Bool = try XCTUnwrap(receivedCancellationNeedsToBeConfirmed)
            XCTAssertTrue(receivedCancellationNeedsToBeConfirmed)
        }
        XCTAssertNil(receivedCancel)
    }
}
