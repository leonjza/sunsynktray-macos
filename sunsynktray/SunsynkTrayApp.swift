import SwiftUI
import AppKit

var VERSION = "1.0.0"

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
                        MenuBar.shared.updateTrayIcon(with: "!")
                        MenuBar.shared.updateToolTip(with: error.localizedDescription)
                    }
                }
            } else {
                return // no username
            }
        }
        
        Task {
            do {
                let info = try await ApiClient.shared.energyFlow(plantId: plantid)
                MenuBar.shared.updateTrayIcon(with: String(Int(info.soc)))
                MenuBar.shared.updateToolTip(with: "Status: PV = \(info.pvPower)W, Batt = \(info.battPower)W, " +
                                                   "Grid = \(info.gridOrMeterPower)W, Load = \(info.loadOrEpsPower)W, SOC = \(info.soc)")
            } catch {
                MenuBar.shared.updateTrayIcon(with: "!")
                MenuBar.shared.updateToolTip(with: error.localizedDescription)
            }
        }
    }
}
