import Foundation

protocol CurrencySelectionModelProtocol {
    var title: String { get }
    
    var allowsMultipleSelection: Bool { get }
    
    var initialSortingOrder: CurrencySelectionModel.SortingOrder { get }
    
    var currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String] { get }

    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool
    
    func getSortingMethod() -> CurrencySelectionModel.SortingMethod
    
    func set(sortingMethod: CurrencySelectionModel.SortingMethod,
             andOrder sortingOrder: CurrencySelectionModel.SortingOrder)
    
    func set(searchText: String?)
    
    func update()
}

// TODO: 要做出一個 name space
extension CurrencySelectionModel {
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
    
    static func sort(_ currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String],
                     bySortingMethod sortingMethod: SortingMethod,
                     andSortingOrder sortingOrder: SortingOrder,
                     thenFilterIfNeedBySearchTextBy searchText: String?) -> [ResponseDataModel.CurrencyCode] {
        
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
                    assertionFailure("###, \(#function), 這段是 dead code")
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

