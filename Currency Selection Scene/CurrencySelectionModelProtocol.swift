import Foundation

protocol CurrencySelectionModelProtocol: BaseCurrencySelectionModelProtocol {
    var currencySelectionStrategy: CurrencySelectionStrategy { get }
    var supportedCurrencyManager: SupportedCurrencyManager { get }
}

extension CurrencySelectionModelProtocol {
    var title: String { currencySelectionStrategy.title }
    
    var allowsMultipleSelection: Bool { currencySelectionStrategy.allowsMultipleSelection }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.select(currencyCode: selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.deselect(currencyCode: deselectedCurrencyCode)
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        currencySelectionStrategy.isCurrencyCodeSelected(currencyCode)
    }
}

extension CurrencySelectionModelProtocol {
    var currencyDescriber: CurrencyDescriberProtocol { supportedCurrencyManager }
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
        let currencyDescriber: CurrencyDescriberProtocol
        
        init(currencyDescriber: CurrencyDescriberProtocol) {
            self.currencyDescriber = currencyDescriber
        }
        
        func sort(_ currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String],
                  bySortingMethod sortingMethod: SortingMethod,
                  andSortingOrder sortingOrder: SortingOrder,
                  thenFilterIfNeedBySearchTextBy searchText: String?) -> [ResponseDataModel.CurrencyCode] {
            let currencyCodes: Dictionary<ResponseDataModel.CurrencyCode, String>.Keys = currencyCodeDescriptionDictionary.keys
            
            let sortedCurrencyCodes: [ResponseDataModel.CurrencyCode] = currencyCodes.sorted { lhs, rhs in
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
                            let zhuyinLocale: Locale = Locale(identifier: "zh@collation=zhuyin")
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
            
            var filteredCurrencyCodes: [ResponseDataModel.CurrencyCode] = sortedCurrencyCodes
            
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
