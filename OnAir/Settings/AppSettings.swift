import Foundation
import Observation
import ServiceManagement

/// All user-configurable settings.
struct AppSettings: Equatable {
    var mqtt = MQTTSettings()
    var cameraTrigger = true
    var micTrigger = true
    var pollInterval: Double = 3
    var launchAtLogin = false
}

/// Shared, observable settings state edited by `ConfigView` and read back by
/// `AppDelegate` when the window closes.
@MainActor
@Observable
final class SettingsModel {
    var settings: AppSettings

    init(_ settings: AppSettings) {
        self.settings = settings
    }
}

enum SettingsStore {
    private static let urlKey = "mqtt.url"
    private static let usernameKey = "mqtt.username"
    private static let topicKey = "mqtt.topic"
    private static let passwordAccount = "mqtt.password"
    /// Plaintext fallback used only when the Keychain write fails (ad-hoc dev builds).
    private static let passwordFallbackKey = "mqtt.password.fallback"
    private static let cameraKey = "trigger.camera"
    private static let micKey = "trigger.mic"
    private static let pollKey = "poll.interval"
    private static let launchKey = "launchAtLogin"

    static func load() -> AppSettings {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            cameraKey: true,
            micKey: true,
            pollKey: 3.0,
        ])
        return AppSettings(
            mqtt: MQTTSettings(
                url: defaults.string(forKey: urlKey) ?? "",
                username: defaults.string(forKey: usernameKey) ?? "",
                topic: defaults.string(forKey: topicKey) ?? "",
                password: KeychainStore.get(passwordAccount)
                    ?? defaults.string(forKey: passwordFallbackKey) ?? ""
            ),
            cameraTrigger: defaults.bool(forKey: cameraKey),
            micTrigger: defaults.bool(forKey: micKey),
            pollInterval: max(1, defaults.double(forKey: pollKey)),
            launchAtLogin: SMAppService.mainApp.status == .enabled
        )
    }

    static func save(_ settings: AppSettings) {
        let defaults = UserDefaults.standard
        defaults.set(settings.mqtt.url, forKey: urlKey)
        defaults.set(settings.mqtt.username, forKey: usernameKey)
        defaults.set(settings.mqtt.topic, forKey: topicKey)
        defaults.set(settings.cameraTrigger, forKey: cameraKey)
        defaults.set(settings.micTrigger, forKey: micKey)
        defaults.set(settings.pollInterval, forKey: pollKey)
        defaults.set(settings.launchAtLogin, forKey: launchKey)
        savePassword(settings.mqtt.password)
    }

    private static func savePassword(_ password: String) {
        let defaults = UserDefaults.standard
        guard !password.isEmpty else {
            KeychainStore.delete(passwordAccount)
            defaults.removeObject(forKey: passwordFallbackKey)
            return
        }
        if KeychainStore.set(password, for: passwordAccount) {
            defaults.removeObject(forKey: passwordFallbackKey)
        } else {
            defaults.set(password, forKey: passwordFallbackKey)
        }
    }
}
