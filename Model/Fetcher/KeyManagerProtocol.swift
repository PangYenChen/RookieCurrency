protocol KeyManagerProtocol {
    func getUsingAPIKeyAfterDeprecating(_ apiKeyToBeDeprecated: String) -> Result<String, Error>
    
    func getUsingAPIKey() -> Result<String, Error>
}
