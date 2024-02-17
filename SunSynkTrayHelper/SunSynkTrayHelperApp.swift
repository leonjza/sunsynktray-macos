import Cocoa

@main
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
            NSWorkspace.shared.openApplication(at: mainAppURL, configuration: configuration) { app, error in
                if let error = error {
                    print("Failed to open main app: \(error.localizedDescription)")
                }
            }
        }
        
        NSApp.terminate(nil)
    }
}
