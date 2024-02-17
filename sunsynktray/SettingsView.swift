import SwiftUI
import ServiceManagement

struct SettingsView: View {
    
    @State private var launchAtStartup = UserDefaults.standard.bool(forKey: "launchAtStartup")
    
    @State private var username: String = UserDefaults.standard.string(forKey: "lastUsername") ?? ""
    @State private var password: String = ""
    @State private var plants: [ApiClient.PlantsResponseDataInfo] = []
    @State private var selectedPlantID: Int?
    
    @State private var stateMessage: String = ""
    @State private var feedbackMessage: String = "Ready"
    @State private var isFetching: Bool = false
    
    init() {

        if let username = UserDefaults.standard.string(forKey: "lastUsername"),
           let password = KeychainManager.getPassword(username: username) {
            _username = State(initialValue: username)
            _password = State(initialValue: password)
        }
        
        // if we have a plantId and username, set a status message
        if let plantid = UserDefaults.standard.string(forKey: "lastPlantId") {
            _stateMessage = State(initialValue: "Using plant ID \(plantid) for user \(username)")
        }
    }

    var body: some View {
        VStack {
            HSplitView {
                // Left side for username and password
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Get Plants") {
                        loginAndFetchPlants()
                    }
                    .padding(.top, 10)
                    Spacer()
                    
                    Toggle("Launch at startup", isOn: $launchAtStartup)
                        .onChange(of: launchAtStartup) { enabled in
                            setLaunchAtStartup(enabled: enabled)
                        }
                }
                .padding()
                .disabled(isFetching)
                
                // Right side for displaying a list of items
                if isFetching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(plants, id: \.id) { plant in
                        HStack {
                            Text(String(plant.id))
                            Text(plant.name)
                            Text("Updated at \(plant.updateAt.formatted())")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if selectedPlantID == plant.id {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPlantID = plant.id
                            plantSelected(plant)
                        }
                    }
                }
            }
            
            Divider()
            
            VStack {
                Text(stateMessage)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text(feedbackMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(VERSION)
                        .padding(.trailing, 10)
                }
                .padding(.leading, 10)
                .padding(.bottom, 10)
            }
        }
    }
    
    func setLaunchAtStartup(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "launchAtStartup")
        
        let helperAppIdentifier = "com.leonjza.SunSynkTrayHelper"
        SMLoginItemSetEnabled(helperAppIdentifier as CFString, enabled)
    }
    
    func loginAndFetchPlants() {
        feedbackMessage = "Checking credentials..."
        isFetching = true
        
        Task {
            // login
            do {
                try await ApiClient.shared.login(u: username, p: password)
                feedbackMessage = "Logged in! Getting plants..."
            } catch {
                feedbackMessage = "Error: \(error)"
                isFetching = false
                return
            }
            
            // save the credentials we just used
            UserDefaults.standard.set(username, forKey: "lastUsername")
            let success = KeychainManager.setOrUpdatePassword(password, forUsername: username)
            if (success != errSecSuccess) {
                feedbackMessage = "Failed to save password in keychain"
                isFetching = false
                return
            }
            
            // get plants
            do {
                plants = try await ApiClient.shared.plants()
                feedbackMessage = "Select a plant to monitor"
            } catch {
                feedbackMessage = "Error: \(error)"
                isFetching = false
                return
            }
            
            isFetching = false
        }
    }
    
    func plantSelected(_ plant: ApiClient.PlantsResponseDataInfo) {
        feedbackMessage = "Fetching info for plant \(plant.id)..."
        
        Task {
            do {
                let info = try await ApiClient.shared.energyFlow(plantId: plant.id)
                // save the plantid
                UserDefaults.standard.set(plant.id, forKey: "lastPlantId")
                
                stateMessage = "Using plant ID \(plant.id) for user \(username)"
                feedbackMessage = "Status: PV = \(info.pvPower)W, Batt = \(info.battPower)W, " +
                "Grid = \(info.gridOrMeterPower)W, Load = \(info.loadOrEpsPower)W, SOC = \(info.soc)"
                
                MenuBar.shared.updateTrayIcon(with: String(Int(info.soc)))
                
            } catch {
                feedbackMessage = "Error: \(error)"
            }
        }
    }
}

#Preview {
    SettingsView()
}
