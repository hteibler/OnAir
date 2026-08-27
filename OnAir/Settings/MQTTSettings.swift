import Foundation

/// MQTT connection settings. Non-secret fields persist in `UserDefaults`;
/// the password lives in the Keychain. Persistence is handled by `SettingsStore`.
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
