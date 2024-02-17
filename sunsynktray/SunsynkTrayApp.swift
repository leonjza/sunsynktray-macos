import SwiftUI
import AppKit

@main
struct SunsynkTrayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var timer: Timer!
    private var count: Int!
    
    override init() {
        super.init()
        
        count = 0
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        MenuBar.shared.CreateMenuBar()
    }
    
    private func timerTick() {
        let plantid = UserDefaults.standard.integer(forKey: "lastPlantId")
        if (plantid == 0) {
            return // we have not configured a plantid. user must go to settings first
        }
        
        if (!ApiClient.shared.isAuthenticated()) {
            if let username = UserDefaults.standard.string(forKey: "lastUsername"),
               let password = KeychainManager.getPassword(username: username) {
                
                if (password == "") {
                    return // no password
                }
                
                Task {
                    do {
                        try await ApiClient.shared.login(u: username, p: password)
                    } catch {
                        print(error)
                    }
                }
            } else {
                return // no username
            }
        }
        
        Task {
            do {
                let energy = try await ApiClient.shared.energyFlow(plantId: plantid)
                MenuBar.shared.updateTrayIcon(with: String(Int(energy.soc)))
            } catch {
                print(error)
            }
        }
    }
}
