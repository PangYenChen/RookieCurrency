import Foundation
// TODO: protocol 名字要想一下
protocol ImperativeCurrencySelectionModelProtocol: CurrencySelectionModelProtocol {
    var resultHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)? { get set }
}
