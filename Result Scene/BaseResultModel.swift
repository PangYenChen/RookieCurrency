import Foundation

class BaseResultModel: CurrencyDescriberHolder {
    init(currencyDescriber: CurrencyDescriberProtocol,
         userSettingManager: UserSettingManagerProtocol) {
        self.currencyDescriber = currencyDescriber
        initialOrder = userSettingManager.resultOrder
    }
    
    let initialOrder: Order
    
    let currencyDescriber: CurrencyDescriberProtocol
    
    // MARK: - hook methods
    func updateState() {
        fatalError("updateState() has not been implemented")
    }
    
    func setOrder(_ order: Order) {
        fatalError("setOrder(_:) has not been implemented")
    }
    
    func setSearchText(_ searchText: String?) {
        fatalError("setSearchText(_:) has not been implemented")
    }
    
    func settingModel() -> SettingModel {
        fatalError("settingModel() has not been implemented")
    }
}

// MARK: - name space
extension BaseResultModel {
    typealias Setting = (numberOfDays: Int,
                         baseCurrencyCode: ResponseDataModel.CurrencyCode,
                         currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>)
    
        /// 資料的排序方式。
        /// 因為要儲存在 UserDefaults，所以 access control 不能是 private。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedName: String {
            switch self {
                case .increasing: R.string.resultScene.increasing()
                case .decreasing: R.string.resultScene.decreasing()
            }
        }
    }

    enum State {
        case updating
        case updated(timestamp: Int, analyzedSortedDataArray: [AnalyzedData])
        case sorted(analyzedSortedDataArray: [AnalyzedData])
        case failure(Error)
    }
    
    struct AnalyzedData: Hashable {
        let currencyCode: ResponseDataModel.CurrencyCode
        let latest: Decimal
        let mean: Decimal
        let deviation: Decimal
    }
    
    class AnalyzedDataSorter: CurrencyDescriberHolder {
        let currencyDescriber: CurrencyDescriberProtocol
        
        init(currencyDescriber: CurrencyDescriberProtocol) {
            self.currencyDescriber = currencyDescriber
        }
        
        func sort(_ analyzedDataArray: [AnalyzedData],
                  by order: Order,
                  filteredIfNeededBy searchText: String?) -> [AnalyzedData] {
            analyzedDataArray
                .sorted { lhs, rhs in
                    switch order {
                        case .increasing: lhs.deviation < rhs.deviation
                        case .decreasing: lhs.deviation > rhs.deviation
                    }
                }
                .filter { analyzedData in
                    guard let searchText, !searchText.isEmpty else { return true }
                    
                    return [analyzedData.currencyCode,
                            displayStringFor(currencyCode: analyzedData.currencyCode)]
                        .compactMap { $0 }
                        .contains { text in text.localizedStandardContains(searchText) }
                }
        }
    }
}
