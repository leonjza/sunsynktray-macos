import SwiftUI
import AppKit

import Cocoa

@main
struct SunsynkTrayAppHelper: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {

        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppBundleIdentifier = "com.leonjza.sunsynktray"
        
        let runningApps = NSWorkspace.shared.runningApplications
        let isMainAppRunning = runningApps.contains { $0.bundleIdentifier == mainAppBundleIdentifier }
        
        if !isMainAppRunning {
            guard let mainAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppBundleIdentifier) else {
                print("Failed to find the main app URL.")
                NSApp.terminate(nil)
                return
            }
            
            let configuration = NSWorkspace.OpenConfiguration()
            let semaphore = DispatchSemaphore(value: 0) // rip 2 hours
            
            NSWorkspace.shared.openApplication(at: mainAppURL, configuration: configuration) { (app, error) in
                if let error = error {
                    print("Failed to open app: \(error.localizedDescription)")
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        NSApp.terminate(nil)
    }
}
