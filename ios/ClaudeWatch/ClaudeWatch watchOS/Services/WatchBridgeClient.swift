import Foundation

/// Lightweight HTTP client for the watch to connect directly to the bridge.
/// Works in simulator (localhost) and on real hardware (LAN).
class WatchBridgeClient: ObservableObject {
    static let shared = WatchBridgeClient()

    @Published var baseURL: URL?
    @Published var token: String?

    var isPaired: Bool { token != nil && baseURL != nil }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    init() {
        // Restore saved credentials
        if let url = UserDefaults.standard.string(forKey: "watch_bridge_url") {
            baseURL = URL(string: url)
        }
        token = UserDefaults.standard.string(forKey: "watch_bridge_token")
    }

    /// Discover bridge by probing localhost ports
    func discover() async -> URL? {
        for port in UInt16(7860)...UInt16(7869) {
            let url = URL(string: "http://127.0.0.1:\(port)/status")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 2
            do {
                let (_, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    let base = URL(string: "http://127.0.0.1:\(port)")!
                    return base
                }
            } catch { continue }
        }
        return nil
    }

    /// Pair with bridge using 6-digit code
    func pair(baseURL: URL, code: String) async throws {
        let url = baseURL.appendingPathComponent("pair")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["code": code])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BridgeError.network }

        if http.statusCode == 200 {
            let result = try JSONDecoder().decode(PairResponse.self, from: data)
            self.baseURL = baseURL
            self.token = result.token
            UserDefaults.standard.set(baseURL.absoluteString, forKey: "watch_bridge_url")
            UserDefaults.standard.set(result.token, forKey: "watch_bridge_token")
        } else if http.statusCode == 429 {
            throw BridgeError.rateLimited
        } else {
            throw BridgeError.invalidCode
        }
    }

    /// Fetch latest events from bridge (polling — simpler than SSE for watch)
    func fetchEvents(since lastEventId: Int = 0) async throws -> [BridgeEvent] {
        guard let baseURL, let token else { throw BridgeError.notPaired }
        let url = baseURL.appendingPathComponent("status")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await session.data(for: request)
        let status = try JSONDecoder().decode(BridgeStatus.self, from: data)
        return [BridgeEvent(state: status.state, hasPty: status.hasPty)]
    }

    func unpair() {
        token = nil
        baseURL = nil
        UserDefaults.standard.removeObject(forKey: "watch_bridge_url")
        UserDefaults.standard.removeObject(forKey: "watch_bridge_token")
    }

    // MARK: - Types

    enum BridgeError: LocalizedError {
        case network, invalidCode, rateLimited, notPaired
        var errorDescription: String? {
            switch self {
            case .network: return "Can't reach bridge"
            case .invalidCode: return "Wrong code"
            case .rateLimited: return "Too many attempts"
            case .notPaired: return "Not paired"
            }
        }
    }

    struct PairResponse: Decodable {
        let token: String
        let sessionId: String
    }

    struct BridgeStatus: Decodable {
        let state: String
        let sessionId: String
        let hasPty: Bool
        let sseClients: Int
        let pendingPermissions: Int
        let eventBufferSize: Int
    }

    struct BridgeEvent {
        let state: String
        let hasPty: Bool
    }
}
