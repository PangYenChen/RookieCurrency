import Foundation

protocol SettingModelFactory {
    func makeSettingModel() -> SettingModel
}

typealias BaseResultModel = QuasiBaseResultModel & SettingModelFactory
