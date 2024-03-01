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

// MARK: - static methods
extension QuasiBaseResultModel {
    /// 這個 method 是給兩個 target 的 subclass 使用的，不寫成 instance method 的原因是，
    /// reactive target 的 subclass 在 initialization 的 phase 1 中使用，所以必須獨立於 instance。
    static func sort(_ analyzedDataArray: [AnalyzedData],
                     by order: Order,
                     filteredIfNeededBy searchText: String?,
                     currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared) -> [AnalyzedData] {
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
                        currencyDescriber.localizedStringFor(currencyCode: analyzedData.currencyCode)]
                    .compactMap { $0 }
                    .contains { text in text.localizedStandardContains(searchText) }
            }
    }
    
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
    
    struct AnalyzedData: Hashable { // TODO: 名字要想一下
        let currencyCode: ResponseDataModel.CurrencyCode
        let latest: Decimal
        let mean: Decimal
        let deviation: Decimal
    }
    
    enum RefreshStatus {
        case process
        case idle(latestUpdateTimestamp: Int?)
    }
}
