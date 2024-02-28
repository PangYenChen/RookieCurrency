import Foundation

protocol BaseSettingModel: CurrencyDescriberProxy {
    var numberOfDays: Int { get }
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode { get }
    
    var editedCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> { get }
    
    func save()
    
    func cancel()
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel
}
