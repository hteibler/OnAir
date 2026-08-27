import SwiftUI

struct ConfigView: View {
    @State private var settings: AppSettings
    private let onApply: (AppSettings) -> Void
    private let onCommit: () -> Void
    private let onClose: () -> Void

    init(
        settings: AppSettings,
        onApply: @escaping (AppSettings) -> Void,
        onCommit: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _settings = State(initialValue: settings)
        self.onApply = onApply
        self.onCommit = onCommit
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("MQTT") {
                    TextField("URL", text: $settings.mqtt.url, prompt: Text("mqtt://broker.example:1883"))
                    TextField("User", text: $settings.mqtt.username)
                    SecureField("Password", text: $settings.mqtt.password)
                    TextField("Topic", text: $settings.mqtt.topic, prompt: Text("/macbook/onair"))
                }
                Section("Triggers") {
                    Toggle("Camera", isOn: $settings.cameraTrigger)
                    Toggle("Microphone", isOn: $settings.micTrigger)
                }
                Section("Polling") {
                    Stepper(
                        "Interval: \(Int(settings.pollInterval)) s",
                        value: $settings.pollInterval,
                        in: 1...60,
                        step: 1
                    )
                }
                Section("General") {
                    Toggle("Launch at login", isOn: $settings.launchAtLogin)
                }
            }
            .formStyle(.grouped)

            Divider()

            VStack(spacing: 8) {
                Text(Self.versionLine)
                    .font(.footnote)
                Text("Provided for free by Herbert Teibler. Distributed 'as is' without warrenty of any kind")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Button("Close", action: onClose)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .frame(width: 420, height: 640)
        .onChange(of: settings) { _, new in onApply(new) }
        .onDisappear(perform: onCommit)
    }

    private static var versionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        var date = Date()
        if let url = Bundle.main.executableURL,
           let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
            date = modified
        }
        return "Version \(version) — \(formatter.string(from: date))"
    }
}
