import Foundation

class BaseResultModel {
    let initialOrder: Order
    
    init() {
        initialOrder = AppUtility.order
    }
}

// MARK: - helper method
extension BaseResultModel {
    final func sort(_ analyzedDataArray: [AnalyzedData],
                    by order: Order,
                    filteredIfNeededBy searchText: String?) -> [AnalyzedData] {
        analyzedDataArray
            .sorted { lhs, rhs in
                switch order {
                case .increasing:
                    return lhs.deviation < rhs.deviation
                case .decreasing:
                    return lhs.deviation > rhs.deviation
                }
            }
            .filter { analyzedData in
                guard let searchText, !searchText.isEmpty else { return true }
                
                return [analyzedData.currencyCode, 
                        Locale.autoupdatingCurrent.localizedString(forCurrencyCode: analyzedData.currencyCode)]
                    .compactMap { $0 }
                    .contains { text in text.localizedStandardContains(searchText) }
            }
    }
}

// MARK: - name space
extension BaseResultModel {
    /// 資料的排序方式。
    /// 因為要儲存在 UserDefaults，所以 access control 不能是 private。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedName: String {
            switch self {
            case .increasing: return R.string.resultScene.increasing()
            case .decreasing: return R.string.resultScene.decreasing()
            }
        }
    }
    
    typealias UserSetting = (numberOfDay: Int, baseCurrency: ResponseDataModel.CurrencyCode, currencyOfInterest: Set<ResponseDataModel.CurrencyCode>)
}

// MARK: - name space
extension BaseResultModel {
    enum State {
        case initialized
        case updating
        case updated(time: Int, analyzedDataArray: [AnalyzedData])
        case failure(Error)
    }
    
    struct AnalyzedData: Hashable {
        let currencyCode: ResponseDataModel.CurrencyCode
        let latest: Decimal
        let mean: Decimal
        let deviation: Decimal
    }
    
    enum MyError: Swift.Error, LocalizedError {
        case foo
#warning("暫時用的error")
        var localizedDescription: String { "暫時用的error" }
        var errorDescription: String? { "暫時用的error" }
    }
}
