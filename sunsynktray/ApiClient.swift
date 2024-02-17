import Foundation

// toggle to enable request proxying via Burp
var DEBUG = false;

class IgnoreTLSErrorsDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // Trust the certificate even if not valid
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

class ApiClient {
    
    static let shared = ApiClient()
    
    private let baseUrl = URL(string: "https://api.sunsynk.net")!
    private var authToken: String?
    private var refreshToken: String?
    private var expiresIn: Int?
    
    private let session: URLSession
    
    enum ApiError: Error {
        case requestFailed(reason: String)
        case notAuthenticated
    }
    
    private init() {
        if (DEBUG) {
            let configuration = URLSessionConfiguration.default
            
            let proxyHost = "127.0.0.1"
            let proxyPort = 8080
            let proxyDict: [AnyHashable: Any] = [
                "HTTPEnable": true,
                "HTTPProxy": proxyHost,
                "HTTPPort": proxyPort,
                "HTTPSEnable": true,
                "HTTPSProxy": proxyHost,
                "HTTPSPort": proxyPort
            ]
            
            configuration.connectionProxyDictionary = proxyDict
            self.session = URLSession(configuration: configuration, delegate: IgnoreTLSErrorsDelegate(), delegateQueue: nil)
        } else {
            self.session = URLSession.shared
        }
    }
    
    func get<T: Codable>(endpoint: String, parameters: [String: String]) async throws -> T {
        
        if (!isAuthenticated()) {
            throw ApiError.notAuthenticated
        }
        
        var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false)!
        
        urlComponents.path = endpoint
        urlComponents.queryItems = parameters.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        
        // content-based ok check
        let isOk: ApiResponse = try JSONDecoder().decode(ApiResponse.self, from: data)
        if (!isOk.success!) {
            throw ApiError.requestFailed(reason: isOk.msg ?? "")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    func post<T: Codable, U: Codable>(endpoint: String, requestBody: T) async throws -> U {
        let url = baseUrl.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = try JSONEncoder().encode(requestBody)
        let (data, _) = try await session.upload(for: request, from: body)
        
        // content-based ok check
        let isOk: ApiResponse = try JSONDecoder().decode(ApiResponse.self, from: data)
        if (!isOk.success!) {
            throw ApiError.requestFailed(reason: isOk.msg ?? "")
        }
        
        return try JSONDecoder().decode(U.self, from: data)
    }
    
    // a slim struct to decode api responses. used to check the success field.
    struct ApiResponse: Codable {
        var code: Int?
        var msg: String?
        var success: Bool?
    }
    
    struct AuthRequest: Codable {
        var username: String
        var password: String
        var grant_type: String = "password"
        var client_id: String = "csp-web"
        var source: String = "sunsynk"
    }

    struct AuthResponse: Codable {
        var data: AuthResponseData
    }
    
    struct AuthResponseData: Codable {
        var access_token: String
        var token_type: String
        var refresh_token: String
        var expires_in: Int
        var scope: String
    }
    
    struct PlantsResponse: Codable {
        var data: PlantsResponseData?
    }
    
    struct PlantsResponseData: Codable {
        var pageSize: Int
        var pageNumber: Int
        var total: Int
        var infos: [PlantsResponseDataInfo]?
    }
    
    struct PlantsResponseDataInfo: Codable, Identifiable {
        var id: Int
        var name: String
        var updateAt: Date
    }
    
    struct EnergyFlowResponse: Codable {
        var data: EnergyFlowResponseData?
    }
    
    struct EnergyFlowResponseData: Codable {
        var pvPower: Int
        var battPower: Int
        var gridOrMeterPower: Int
        var loadOrEpsPower: Int
        var soc: Float
    }
    
    func isAuthenticated() -> Bool {
        if (authToken == nil || authToken == "") {
            return false
        }
        
        return true
    }
    
    func login(u: String, p: String) async throws {
        let authReq = AuthRequest(username: u, password: p)
        let auth: AuthResponse = try await post(endpoint: "/oauth/token", requestBody: authReq)
        
        authToken = auth.data.access_token
        refreshToken = auth.data.refresh_token
        expiresIn = auth.data.expires_in
    }
    
    func plants() async throws -> [PlantsResponseDataInfo] {
        let plants: PlantsResponse = try await get(endpoint: "/api/v1/plants", 
                                                   parameters: ["page": "1", "limit": "10", "name": "", "status": ""])
        return (plants.data?.infos)!
    }
    
    func energyFlow(plantId: Int) async throws -> EnergyFlowResponseData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let flow: EnergyFlowResponse = try await get(endpoint: "/api/v1/plant/energy/\(plantId)/flow", 
                                                     parameters: ["date": dateFormatter.string(from: Date())])
        return (flow.data)!
    }
}
