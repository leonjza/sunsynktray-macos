import Foundation
import SwiftUI

class MenuBar: NSObject {
    static let shared = MenuBar()
    
    private var statusBar: NSStatusItem!
    private var settingsWindow: NSWindow?
    
    func CreateMenuBar() {
        statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBar.button {
            button.image = NSImage(systemSymbolName: "bolt.horizontal", accessibilityDescription: "SunSynkTray")
            button.toolTip = "SunSynkTray"
        }
        
        populateMenu()
    }
    
    private func populateMenu() {
        let menu = NSMenu()
        
        let menuItems = [
            ("Settings", #selector(toggleSettings), "s"),
            ("Quit", #selector(quitApp), "q")
        ]
        
        for (title, action, key) in menuItems {
            let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
            menuItem.target = self
            menu.addItem(menuItem)
        }
        
        statusBar.menu = menu
    }
    
    func updateTrayIcon(with text: String) {
        let attributes = [
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: NSColor.white
        ]

        let size = text.size(withAttributes: attributes)
        let image = NSImage(size: size)
        image.lockFocus()
        text.draw(at: NSPoint(x: 0, y: 0), withAttributes: attributes)
        image.unlockFocus()
        
        DispatchQueue.main.async { [self] in
            statusBar.button?.image = image
        }
    }
    
    func updateToolTip(with text: String) {
        DispatchQueue.main.async { [self] in
            statusBar.button?.toolTip = "SynSynkTray: \(text)"
        }
    }
    
    @objc func toggleSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 300),
                                      styleMask: [.titled, .closable],
                                      backing: .buffered, defer: false)
            settingsWindow?.center()
            settingsWindow?.setFrameAutosaveName("Settings")
            settingsWindow?.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow?.title = "SunSynkTray Settings"
        }

        settingsWindow?.isReleasedWhenClosed = false
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
