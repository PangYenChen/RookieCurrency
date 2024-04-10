enum HistoricalRateProviderChain {
    static let shared: HistoricalRateProviderProtocol = {
        let historicalRateArchiverRing = HistoricalRateRing(storage: HistoricalRateArchiver(),
                                                            nextProvider: Fetcher.shared)
        
        return HistoricalRateRing(storage: HistoricalRateCache(),
                                  nextProvider: historicalRateArchiverRing)
    }()
}
