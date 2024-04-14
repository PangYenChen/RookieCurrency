enum HistoricalRateProviderChain {
    static let shared: HistoricalRateProviderProtocol = {
        let historicalRateArchiverRing: HistoricalRateProviderRing = HistoricalRateProviderRing(
            storage: HistoricalRateArchiver(fileManager: .default),
            nextProvider: Fetcher.shared
        )
        
        return HistoricalRateProviderRing(storage: HistoricalRateCache(),
                                          nextProvider: historicalRateArchiverRing)
    }()
}
