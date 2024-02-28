import Foundation

protocol BaseSettingModel: CurrencyDescriberProxy {
    var editedNumberOfDays: Int { get }
    
    var editedBaseCurrencyCode: ResponseDataModel.CurrencyCode { get }
    
    func save()
    
    func cancel()
    
    func makeBaseCurrencySelectionModel() -> CurrencySelectionModel
    
    func makeCurrencyOfInterestSelectionModel() -> CurrencySelectionModel
}
