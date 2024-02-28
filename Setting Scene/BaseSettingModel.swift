import Foundation

protocol BaseSettingModel: CurrencyDescriberProxy {
    // TODO:  把 edited 的前綴拿掉，因為剛進這個 scene 的時候其實還沒編輯
    var editedNumberOfDays: Int { get }
    
    var editedBaseCurrencyCode: ResponseDataModel.CurrencyCode { get }
    
    var editedCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> { get }
    
    func save()
    
    func cancel()
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel
}
