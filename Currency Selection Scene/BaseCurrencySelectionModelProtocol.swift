import Foundation

protocol BaseCurrencySelectionModelProtocol: CurrencyDescriberHolder {
    var title: String { get }
    
    var allowsMultipleSelection: Bool { get }
    
    var initialSortingOrder: CurrencySelectionModel.SortingOrder { get }

    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode)
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool
    
    func getSortingMethod() -> CurrencySelectionModel.SortingMethod
    
    func set(sortingMethod: CurrencySelectionModel.SortingMethod,
             andOrder sortingOrder: CurrencySelectionModel.SortingOrder)
    
    func set(searchText: String?)
    
    func update()
}

// MARK: - name space
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
    
    class CurrencyCodeDescriptionDictionarySorter: CurrencyDescriberHolder {
        static let shared: CurrencyCodeDescriptionDictionarySorter = CurrencyCodeDescriptionDictionarySorter()
        
        var currencyDescriber: CurrencyDescriber
        
        init(currencyDescriber: CurrencyDescriber = SupportedCurrencyManager.shared) {
            self.currencyDescriber = currencyDescriber
        }
        
        func sort(_ currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String],
                  bySortingMethod sortingMethod: SortingMethod,
                  andSortingOrder sortingOrder: SortingOrder,
                  thenFilterIfNeedBySearchTextBy searchText: String?) -> [ResponseDataModel.CurrencyCode] {
            
            let currencyCodes = currencyCodeDescriptionDictionary.keys
            
            let sortedCurrencyCodes = currencyCodes.sorted { lhs, rhs in
                
                switch sortingMethod {
                case .currencyName, .currencyNameZhuyin:
                    let lhsString: String = displayStringFor(currencyCode: lhs)
                    let rhsString: String = displayStringFor(currencyCode: rhs)
                    
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
                        [currencyCode, displayStringFor(currencyCode: currencyCode)]
                            .compactMap { $0 }
                            .contains { text in text.localizedStandardContains(searchText) }
                    }
            }
            
            return filteredCurrencyCodes
        }
    }
}
