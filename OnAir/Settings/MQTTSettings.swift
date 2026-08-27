import Foundation

/// MQTT connection settings. Non-secret fields persist in `UserDefaults`;
/// the password lives in the Keychain.
struct MQTTSettings: Equatable {
    var url: String = ""
    var username: String = ""
    var topic: String = ""
    var password: String = ""

    var isConfigured: Bool {
        !url.trimmingCharacters(in: .whitespaces).isEmpty &&
        !topic.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

enum MQTTSettingsStore {
    private static let urlKey = "mqtt.url"
    private static let usernameKey = "mqtt.username"
    private static let topicKey = "mqtt.topic"
    private static let passwordAccount = "mqtt.password"

    static func load() -> MQTTSettings {
        let defaults = UserDefaults.standard
        return MQTTSettings(
            url: defaults.string(forKey: urlKey) ?? "",
            username: defaults.string(forKey: usernameKey) ?? "",
            topic: defaults.string(forKey: topicKey) ?? "",
            password: KeychainStore.get(passwordAccount) ?? ""
        )
    }

    static func save(_ settings: MQTTSettings) {
        let defaults = UserDefaults.standard
        defaults.set(settings.url, forKey: urlKey)
        defaults.set(settings.username, forKey: usernameKey)
        defaults.set(settings.topic, forKey: topicKey)
        if settings.password.isEmpty {
            KeychainStore.delete(passwordAccount)
        } else {
            KeychainStore.set(settings.password, for: passwordAccount)
        }
    }
}
