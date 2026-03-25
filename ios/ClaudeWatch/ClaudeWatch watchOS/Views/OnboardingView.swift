import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: WatchViewState
    @StateObject private var bridge = WatchBridgeClient.shared

    @State private var code = ""
    @State private var isSearching = false
    @State private var isConnecting = false
    @State private var error: String?
    @State private var bridgeURL: URL?
    @FocusState private var codeFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ClaudeMascot(size: 30)

                Text("Claude Watch")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Text.primary)

                if isSearching {
                    HStack(spacing: 4) {
                        ProgressView().scaleEffect(0.6)
                        Text("Finding bridge...")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Text.secondary)
                    }
                } else if bridgeURL != nil {
                    // Bridge found — show code entry
                    Text("Enter pairing code")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Text.secondary)

                    TextField("000000", text: $code)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Text.primary)
                        .multilineTextAlignment(.center)
                        .textContentType(.oneTimeCode)
                        .focused($codeFocused)
                        .onChange(of: code) { _, newValue in
                            // Only allow digits, max 6
                            let filtered = String(newValue.filter { $0.isNumber }.prefix(6))
                            if filtered != newValue { code = filtered }
                            if filtered.count == 6 { submitCode(filtered) }
                        }

                    if isConnecting {
                        HStack(spacing: 4) {
                            ProgressView().scaleEffect(0.6)
                            Text("Pairing...")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Text.secondary)
                        }
                    }
                } else {
                    // No bridge found
                    Text("Start bridge on Mac:")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Text.secondary)
                    Text("node server.js")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.Text.primary)

                    Button("Retry") { searchForBridge() }
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Text.primary)
                }

                if let error {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Accent.error)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
        }
        .background(Theme.Background.primary)
        .onAppear { searchForBridge() }
    }

    private func searchForBridge() {
        isSearching = true
        error = nil
        Task {
            let url = await bridge.discover()
            await MainActor.run {
                isSearching = false
                bridgeURL = url
                if url != nil {
                    codeFocused = true
                }
            }
        }
    }

    private func submitCode(_ code: String) {
        guard let url = bridgeURL, !isConnecting else { return }
        isConnecting = true
        error = nil

        Task {
            do {
                try await bridge.pair(baseURL: url, code: code)
                await MainActor.run {
                    session.isPaired = true
                    session.sessionState = SessionState(
                        connection: .connected, activity: .idle,
                        machineName: "Mac", modelName: nil,
                        workingDirectory: nil,
                        elapsedSeconds: 0, filesChanged: 0, linesAdded: 0,
                        transportMode: .lan
                    )
                    session.appendLine(TerminalLine(text: "Connected to bridge", type: .system))
                    session.startEventStream()
                }
            } catch {
                await MainActor.run {
                    self.isConnecting = false
                    self.error = error.localizedDescription
                    self.code = ""
                }
            }
        }
    }
}

#Preview { OnboardingView().environmentObject(WatchViewState.shared) }
