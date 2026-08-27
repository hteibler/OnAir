import AppKit
import OSLog
import SwiftUI

private let log = Logger(subsystem: "at.teibler.OnAir", category: "monitor")

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var configWindow: NSWindow?

    private let monitor = DeviceStateMonitor()

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

        monitor.onChange = { [weak self] _, new in
            self?.updateStatusIcon(for: new)
            log.notice("camera=\(new.camera, privacy: .public) mic=\(new.microphone, privacy: .public)")
        }
        monitor.start()
        updateStatusIcon(for: monitor.state)
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
        } else {
            monitor.start()
        }
        updateStatusIcon(for: monitor.state)
    }

    private func updateStatusIcon(for state: DeviceState) {
        guard let button = statusItem.button else { return }

        let symbol: String
        let tooltip: String
        if !monitor.isEnabled {
            symbol = "dot.radiowaves.left.and.right"
            tooltip = "OnAir — paused"
        } else if state.camera {
            symbol = "video.fill"
            tooltip = state.microphone ? "OnAir — camera + mic active" : "OnAir — camera active"
        } else if state.microphone {
            symbol = "mic.fill"
            tooltip = "OnAir — mic active"
        } else {
            symbol = "dot.radiowaves.left.and.right"
            tooltip = "OnAir — idle"
        }

        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        button.appearsDisabled = !monitor.isEnabled
        button.contentTintColor = monitor.isEnabled && (state.camera || state.microphone) ? .systemRed : nil
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
