import Foundation

protocol SettingModelFactory {
    func makeSettingModel() -> SettingModel
}

protocol ResultRefresher {
    func refresh()
}

typealias BaseResultModel = QuasiBaseResultModel & SettingModelFactory & ResultRefresher
