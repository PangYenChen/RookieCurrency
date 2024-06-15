protocol HistoricalRateStorageProtocol: CustomStringConvertible {
    func readFor(dateString: String) -> ResponseDataModel.HistoricalRate?
    func store(_ rate: ResponseDataModel.HistoricalRate)
    func removeAll()
}
