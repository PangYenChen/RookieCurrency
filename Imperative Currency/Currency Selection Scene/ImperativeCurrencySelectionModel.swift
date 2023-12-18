import Foundation
// TODO: 名字要想一下
protocol ImperativeCurrencySelectionModelProtocol: CurrencySelectionModelProtocol {
    var stateHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)? { get set }
}
