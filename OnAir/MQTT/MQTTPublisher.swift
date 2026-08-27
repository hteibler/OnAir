import Foundation
import MQTT
import OSLog

private let log = Logger(subsystem: "at.teibler.OnAir", category: "mqtt")

/// Wraps an `MQTTClient.V5` and publishes camera / mic state changes.
///
/// All methods and the `onConnectionChange` callback run on the main actor:
/// `connect` / `disconnect` / `publish` are called from `AppDelegate`, and the
/// client's `delegateQueue` is set to `.main`, so the `nonisolated` delegate
/// callbacks can safely assume main-actor isolation.
@MainActor
final class MQTTPublisher: NSObject {
    /// Called when the connected state changes.
    var onConnectionChange: ((Bool) -> Void)?
    private(set) var isConnected = false

    private var client: MQTTClient.V5?
    private var topic = ""

    func connect(_ settings: MQTTSettings) {
        disconnect()

        guard let endpoint = MQTTEndpointParser.endpoint(from: settings.url) else {
            log.error("invalid broker URL: \(settings.url, privacy: .public)")
            return
        }

        topic = settings.topic.trimmingCharacters(in: .whitespaces)
        let client = MQTTClient.V5(endpoint)
        client.config.keepAlive = 60
        client.delegateQueue = .main
        client.delegate = self
        client.startMonitor()
        client.startRetrier(.exponential(), limits: .max)
        self.client = client

        let identity = Identity(
            Self.clientId,
            username: settings.username.isEmpty ? nil : settings.username,
            password: settings.password.isEmpty ? nil : settings.password
        )
        log.notice("connecting to \(settings.url, privacy: .public)")
        client.open(identity)
    }

    func disconnect() {
        client?.stopRetrier()
        client?.stopMonitor()
        client?.close()
        client = nil
        setConnected(false)
    }

    func publish(camera isOn: Bool) { publish(key: "camera", isOn: isOn) }
    func publish(mic isOn: Bool) { publish(key: "mic", isOn: isOn) }

    private func publish(key: String, isOn: Bool) {
        guard let client, !topic.isEmpty else { return }
        let payload = "{\"\(key)\":\"\(isOn ? "on" : "off")\",\"timestamp\":\(Int(Date().timeIntervalSince1970))}"
        client.publish(to: topic, payload: payload, qos: .atMostOnce, retain: true)
        log.notice("published \(payload, privacy: .public)")
    }

    private func setConnected(_ value: Bool) {
        guard value != isConnected else { return }
        isConnected = value
        onConnectionChange?(value)
    }

    private static var clientId: String {
        "OnAir-\(ProcessInfo.processInfo.hostName)"
    }
}

extension MQTTPublisher: MQTTDelegate {
    nonisolated func mqtt(_ mqtt: MQTTClient, didUpdate status: Status, prev: Status) {
        MainActor.assumeIsolated { setConnected(status == .opened) }
    }

    nonisolated func mqtt(_ mqtt: MQTTClient, didReceive message: Message) {}

    nonisolated func mqtt(_ mqtt: MQTTClient, didReceive error: any Error) {
        log.error("client error: \(String(describing: error), privacy: .public)")
    }
}
