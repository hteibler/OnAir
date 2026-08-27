import AppKit
import OSLog
import SwiftUI

private let log = Logger(subsystem: "at.teibler.OnAir", category: "monitor")

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var configWindow: NSWindow?

    private let monitor = DeviceStateMonitor()
    private let publisher = MQTTPublisher()
    private var settings = MQTTSettingsStore.load()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        menu = NSMenu()
        let configItem = menu.addItem(withTitle: "Configure…", action: #selector(openConfig), keyEquivalent: ",")
        configItem.target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit OnAir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        monitor.onChange = { [weak self] old, new in
            guard let self else { return }
            if old.camera != new.camera { self.publisher.publish(camera: new.camera) }
            if old.microphone != new.microphone { self.publisher.publish(mic: new.microphone) }
            self.updateStatusIcon()
            log.notice("camera=\(new.camera, privacy: .public) mic=\(new.microphone, privacy: .public)")
        }

        publisher.onConnectionChange = { [weak self] connected in
            guard let self else { return }
            if connected {
                // Refresh the retained topic so it reflects reality after a restart.
                self.publisher.publish(camera: self.monitor.state.camera)
                self.publisher.publish(mic: self.monitor.state.microphone)
            }
            self.updateStatusIcon()
        }

        monitor.start()
        connectMQTT()
        updateStatusIcon()
    }

    // MARK: - Status item

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleEnabled()
        }
    }

    private func toggleEnabled() {
        if monitor.isEnabled {
            monitor.stop()
            publisher.disconnect()
        } else {
            monitor.start()
            connectMQTT()
        }
        updateStatusIcon()
    }

    private func connectMQTT() {
        settings = MQTTSettingsStore.load()
        guard settings.isConfigured else {
            log.notice("MQTT not configured — skipping connect")
            return
        }
        publisher.connect(settings)
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        let state = monitor.state

        let symbol: String
        let tooltip: String
        var tint: NSColor?

        if !monitor.isEnabled {
            symbol = "dot.radiowaves.left.and.right"
            tooltip = "OnAir — paused"
        } else if settings.isConfigured && !publisher.isConnected {
            symbol = "antenna.radiowaves.left.and.right.slash"
            tooltip = "OnAir — MQTT unreachable"
        } else if state.camera {
            symbol = "video.fill"
            tooltip = state.microphone ? "OnAir — camera + mic active" : "OnAir — camera active"
            tint = .systemRed
        } else if state.microphone {
            symbol = "mic.fill"
            tooltip = "OnAir — mic active"
            tint = .systemRed
        } else {
            symbol = "dot.radiowaves.left.and.right"
            tooltip = "OnAir — idle"
        }

        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        button.appearsDisabled = !monitor.isEnabled
        button.contentTintColor = tint
        button.toolTip = tooltip
    }

    // MARK: - Config window

    @objc private func openConfig() {
        if configWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 360),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "OnAir"
            window.contentViewController = NSHostingController(rootView: ConfigView())
            window.isReleasedWhenClosed = false
            window.center()
            configWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        configWindow?.makeKeyAndOrderFront(nil)
    }
}
