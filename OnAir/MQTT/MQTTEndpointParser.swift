import Foundation
import MQTT

/// Parses a broker URL string into an `MQTT.Endpoint`.
///
/// Accepted forms:
/// - `mqtt://host[:port]` / `tcp://host[:port]`   → plain TCP (default port 1883)
/// - `mqtts://host[:port]` / `ssl://host[:port]`  → TLS (default port 8883, system trust)
/// - `ws://host[:port][/path]`                    → WebSocket (default port 8083, path `/mqtt`)
/// - `wss://host[:port][/path]`                   → WebSocket over TLS (default port 8084)
/// - `host[:port]` (no scheme)                    → treated as `mqtt://`
enum MQTTEndpointParser {
    static func endpoint(from string: String) -> Endpoint? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.contains("://") ? trimmed : "mqtt://\(trimmed)"
        guard let url = URL(string: normalized), let host = url.host, !host.isEmpty else {
            return nil
        }

        let port = url.port.flatMap { UInt16(exactly: $0) }
        let path = url.path.isEmpty ? "/mqtt" : url.path

        switch url.scheme?.lowercased() {
        case "mqtt", "tcp", nil:
            return .tcp(host: host, port: port ?? 1883)
        case "mqtts", "ssl", "tls":
            return .tls(host: host, port: port ?? 8883)
        case "ws":
            return .ws(host: host, port: port ?? 8083, path: path)
        case "wss":
            return .wss(host: host, port: port ?? 8084, path: path)
        default:
            return nil
        }
    }
}
