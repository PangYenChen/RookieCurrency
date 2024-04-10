enum HistoricalRateProviderChain {
    static let shared: HistoricalRateProviderProtocol = {
        let historicalRateArchiverRing: HistoricalRateProviderRing = HistoricalRateProviderRing(storage: HistoricalRateArchiver(),
                                                                                nextProvider: Fetcher.shared)
        
        return HistoricalRateProviderRing(storage: HistoricalRateCache(),
                                  nextProvider: historicalRateArchiverRing)
    }()
}
