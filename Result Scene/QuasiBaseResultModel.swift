import Foundation

class QuasiBaseResultModel: CurrencyDescriberProxy {
    init(currencyDescriber: CurrencyDescriberProtocol,
         userSettingManager: UserSettingManagerProtocol) {
        self.currencyDescriber = currencyDescriber
        initialOrder = userSettingManager.resultOrder
    }
    
    let initialOrder: Order
    
    let currencyDescriber: CurrencyDescriberProtocol
}

// MARK: - static property
extension QuasiBaseResultModel {
    static let autoRefreshTimeInterval: TimeInterval = 5
}

// MARK: - name space
extension QuasiBaseResultModel {
    typealias Setting = (numberOfDays: Int,
                         baseCurrencyCode: ResponseDataModel.CurrencyCode,
                         currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>)
    
    /// 資料的排序方式。
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
    
    enum State { // TODO: 可能要重新設計這個
        case updating
        case updated(timestamp: Int, analyzedSortedDataArray: [AnalyzedData])
        case sorted(analyzedSortedDataArray: [AnalyzedData])
        case failure(Error)
    }
    
    struct AnalyzedData: Hashable { // TODO: 名字要想一下
        let currencyCode: ResponseDataModel.CurrencyCode
        let latest: Decimal
        let mean: Decimal
        let deviation: Decimal
    }
    
    class AnalyzedDataSorter: CurrencyDescriberProxy {
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
    
    enum UpdatingStatus {
        case process
        case idle(latestUpdateTimestamp: Int?)
    }
}
