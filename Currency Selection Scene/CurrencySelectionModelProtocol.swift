import Foundation

protocol CurrencySelectionModelProtocol {
    
    var title: String { get }
    
    var selectedCurrencyCode: Set<ResponseDataModel.CurrencyCode> { get }
    
    var allowsMultipleSelection: Bool { get }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func getSortingMethod() -> SortingMethod
    
    func set(sortingMethod: SortingMethod, andOrder sortingOrder: SortingOrder)
    
    @available(*, deprecated, message: "邏輯全部搬到 model 後，要刪掉這個 method")
    func getSortingOrder() -> SortingOrder
    
    func set(searchText: String?)
    
    @available(*, deprecated, message: "邏輯全部搬到 model 後，要刪掉這個 method")
    func getSearchText() -> String?
    
    func fetch()
    
    @available(*, deprecated, message: "邏輯全部搬到 model 後，要刪掉這個屬性")
    var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String] { get }
}

extension CurrencySelectionModelProtocol {
    func convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String],
                                          sortingMethod: SortingMethod,
                                          sortingOrder: SortingOrder,
                                          searchText: String?) -> [ResponseDataModel.CurrencyCode] {
        
        let currencyCodes = currencyCodeDescriptionDictionary.keys
        
        let sortedCurrencyCodes = currencyCodes.sorted { lhs, rhs in
            
            switch sortingMethod {
            case .currencyName, .currencyNameZhuyin:
                let lhsString: String
                do {
                    let lhsLocalizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: lhs)
                    let lhsServerCurrencyDescription = currencyCodeDescriptionDictionary[lhs]
                    lhsString = lhsLocalizedCurrencyDescription ?? lhsServerCurrencyDescription ?? lhs
                }
                
                let rhsString: String
                do {
                    let rhsLocalizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: rhs)
                    let rhsServerCurrencyDescription = currencyCodeDescriptionDictionary[rhs]
                    rhsString = rhsLocalizedCurrencyDescription ?? rhsServerCurrencyDescription ?? rhs
                }
                
                if sortingMethod == .currencyName {
                    switch sortingOrder {
                    case .ascending:
                        return lhsString.localizedStandardCompare(rhsString) == .orderedAscending
                    case .descending:
                        return lhsString.localizedStandardCompare(rhsString) == .orderedDescending
                    }
                }
                else if sortingMethod == .currencyNameZhuyin {
                    let zhuyinLocale = Locale(identifier: "zh@collation=zhuyin")
                    switch sortingOrder {
                    case .ascending:
                        return lhsString.compare(rhsString, locale: zhuyinLocale) == .orderedAscending
                    case .descending:
                        return lhsString.compare(rhsString, locale: zhuyinLocale) == .orderedDescending
                    }
                }
                else {
                    assertionFailure("###, \(self), \(#function), 這段是 dead code")
                    return false
                }
                
            case .currencyCode:
                switch sortingOrder {
                case .ascending:
                    return lhs.localizedStandardCompare(rhs) == .orderedAscending
                case .descending:
                    return lhs.localizedStandardCompare(rhs) == .orderedDescending
                }
            }
        }
        
        var filteredCurrencyCodes = sortedCurrencyCodes
        
        if let searchText, !searchText.isEmpty {
            filteredCurrencyCodes = sortedCurrencyCodes
                .filter { currencyCode in
                    [currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)]
                        .compactMap { $0 }
                        .contains { text in text.localizedStandardContains(searchText) }
                }
        }
        
        return filteredCurrencyCodes
    }
}

// TODO: 要做出一個 name space
enum SortingMethod {
    case currencyName
    case currencyCode
    case currencyNameZhuyin
    
    var localizedName: String {
        switch self {
        case .currencyName: return R.string.currencyScene.currencyName()
        case .currencyCode: return R.string.currencyScene.currencyCode()
        case .currencyNameZhuyin: return R.string.currencyScene.currencyZhuyin()
        }
    }
}

enum SortingOrder {
    case ascending
    case descending
    
    var localizedName: String {
        switch self {
        case .ascending: return R.string.currencyScene.ascending()
        case .descending: return R.string.currencyScene.descending()
        }
    }
}
