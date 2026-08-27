import AppKit
import OSLog
import ServiceManagement
import SwiftUI

private let log = Logger(subsystem: "at.teibler.OnAir", category: "monitor")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var configWindow: NSWindow?

    private let monitor = DeviceStateMonitor()
    private let publisher = MQTTPublisher()
    private var settings = SettingsStore.load()
    private var lastConnectedMQTT: MQTTSettings?

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
            if old.camera != new.camera, self.settings.cameraTrigger {
                self.publisher.publish(camera: new.camera)
            }
            if old.microphone != new.microphone, self.settings.micTrigger {
                self.publisher.publish(mic: new.microphone)
            }
            self.updateStatusIcon()
            log.notice("camera=\(new.camera, privacy: .public) mic=\(new.microphone, privacy: .public)")
        }

        publisher.onConnectionChange = { [weak self] connected in
            guard let self else { return }
            if connected {
                // Refresh the retained topic so it reflects reality after a restart.
                if self.settings.cameraTrigger { self.publisher.publish(camera: self.monitor.state.camera) }
                if self.settings.micTrigger { self.publisher.publish(mic: self.monitor.state.microphone) }
            }
            self.updateStatusIcon()
        }

        monitor.setPollInterval(settings.pollInterval)
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
            lastConnectedMQTT = nil
        } else {
            monitor.start()
            connectMQTT()
        }
        updateStatusIcon()
    }

    // MARK: - MQTT

    private func connectMQTT() {
        guard monitor.isEnabled, settings.mqtt.isConfigured else {
            log.notice("MQTT not configured or paused — skipping connect")
            return
        }
        publisher.connect(settings.mqtt)
        lastConnectedMQTT = settings.mqtt
    }

    private func reconnectMQTT() {
        guard settings.mqtt != lastConnectedMQTT else { return }
        publisher.disconnect()
        connectMQTT()
        updateStatusIcon()
    }

    // MARK: - Settings

    private func applySettings(_ new: AppSettings) {
        settings = new
        SettingsStore.save(new)
        monitor.setPollInterval(new.pollInterval)
        applyLaunchAtLogin(new.launchAtLogin)
        updateStatusIcon()
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled, service.status != .enabled {
                try service.register()
            } else if !enabled, service.status == .enabled {
                try service.unregister()
            }
        } catch {
            log.error("launch-at-login \(enabled, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            settings.launchAtLogin = service.status == .enabled
        }
    }

    // MARK: - Status icon

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        let cameraActive = settings.cameraTrigger && monitor.state.camera
        let micActive = settings.micTrigger && monitor.state.microphone

        let symbol: String
        let tooltip: String
        var tint: NSColor?

        if !monitor.isEnabled {
            symbol = "dot.radiowaves.left.and.right"
            tooltip = "OnAir — paused"
        } else if settings.mqtt.isConfigured && !publisher.isConnected {
            symbol = "antenna.radiowaves.left.and.right.slash"
            tooltip = "OnAir — MQTT unreachable"
        } else if cameraActive {
            symbol = "video.fill"
            tooltip = micActive ? "OnAir — camera + mic active" : "OnAir — camera active"
            tint = .systemRed
        } else if micActive {
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
        let window: NSWindow
        if let existing = configWindow {
            window = existing
        } else {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 640),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "OnAir"
            window.isReleasedWhenClosed = false
            window.center()
            configWindow = window
        }

        let view = ConfigView(
            settings: settings,
            onApply: { [weak self] new in self?.applySettings(new) },
            onCommit: { [weak self] in self?.reconnectMQTT() },
            onClose: { [weak self] in self?.configWindow?.close() }
        )
        window.contentViewController = NSHostingController(rootView: view)

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
