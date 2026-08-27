import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var configWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "dot.radiowaves.left.and.right",
            accessibilityDescription: "OnAir"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "Configure…", action: #selector(openConfig), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit OnAir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for item in menu.items where item.action == #selector(openConfig) {
            item.target = self
        }
        statusItem.menu = menu
    }

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
