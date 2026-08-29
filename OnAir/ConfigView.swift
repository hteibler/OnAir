import SwiftUI

struct ConfigView: View {
    @Bindable var model: SettingsModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("MQTT") {
                    TextField("URL", text: $model.settings.mqtt.url, prompt: Text("mqtt://broker.example:1883"))
                    TextField("User", text: $model.settings.mqtt.username)
                    SecureField("Password", text: $model.settings.mqtt.password)
                    TextField("Topic", text: $model.settings.mqtt.topic, prompt: Text("/macbook/onair"))
                }
                Section("Triggers") {
                    Toggle("Camera", isOn: $model.settings.cameraTrigger)
                    Toggle("Microphone", isOn: $model.settings.micTrigger)
                }
                Section("Polling") {
                    Stepper(
                        "Interval: \(Int(model.settings.pollInterval)) s",
                        value: $model.settings.pollInterval,
                        in: 1...60,
                        step: 1
                    )
                }
                Section("General") {
                    Toggle("Launch at login", isOn: $model.settings.launchAtLogin)
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
        .onChange(of: model.settings) { _, new in
            // Persist on every edit; AppDelegate applies side effects (poll
            // interval, launch-at-login, MQTT reconnect) when the window closes.
            SettingsStore.save(new)
        }
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
