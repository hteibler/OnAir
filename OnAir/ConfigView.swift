import SwiftUI

struct ConfigView: View {
    private var versionString: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "Version \(short)"
    }

    private var buildDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if let url = Bundle.main.executableURL,
           let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let date = attrs[.modificationDate] as? Date {
            return formatter.string(from: date)
        }
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OnAir")
                .font(.title2.bold())

            Text("Configuration UI to be implemented.")
                .foregroundStyle(.secondary)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(versionString) — \(buildDate)")
                Text("Provided for free by Herbert Teibler. Distributed 'as is' without warrenty of any kind")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420, height: 360)
    }
}
