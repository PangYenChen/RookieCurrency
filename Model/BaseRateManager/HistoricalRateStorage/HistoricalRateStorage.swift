protocol HistoricalRateStorage {
    func readFor(dateString: String) -> ResponseDataModel.HistoricalRate?
    func store(_ rate: ResponseDataModel.HistoricalRate)
    func removeCachedAndStoredRate()
}
