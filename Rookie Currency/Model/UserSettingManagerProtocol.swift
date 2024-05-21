protocol UserSettingManagerProtocol {
    var numberOfDays: Int { get set }
    
    var baseCurrencyCode: ResponseDataModel.CurrencyCode { get set }
    
    var resultOrder: BaseResultModel.Order { get set }
    
    var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> { get set }
}
