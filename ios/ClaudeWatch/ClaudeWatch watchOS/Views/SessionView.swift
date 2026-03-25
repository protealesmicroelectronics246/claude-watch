import SwiftUI

// MARK: - SessionView

struct SessionView: View {
    @EnvironmentObject private var session: WatchViewState

    @State private var showVoiceInput = false
    @State private var cursorVisible = true
    private let cursorTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Full-screen terminal
            VStack(spacing: 0) {
                // Thin top bar
                HStack(spacing: 4) {
                    ClaudeMascot(size: 14)
                    Text("Claude")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Text.primary)
                    Spacer()
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)

                // Terminal fills everything
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(session.terminalLines) { line in
                                Text(line.text)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(colorFor(line.type))
                                    .id(line.id)
                            }

                            if isThinking {
                                Text(cursorVisible ? "\u{2588}" : " ")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Theme.Text.primary)
                                    .onReceive(cursorTimer) { _ in cursorVisible.toggle() }
                            }

                            // Bottom padding so content isn't hidden behind FAB
                            Color.clear.frame(height: 40)
                        }
                        .padding(.horizontal, 4)
                    }
                    .onChange(of: session.terminalLines.count) { _ in
                        if let last = session.terminalLines.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Theme.Background.primary)

            // Floating mic button — bottom right, small with transparency
            Button { showVoiceInput = true } label: {
                ZStack {
                    Circle()
                        .fill(Theme.Text.primary.opacity(0.75))
                        .frame(width: 28, height: 28)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                }
                .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(item: $session.pendingApproval) { request in
            ApprovalView(request: request)
        }
        .fullScreenCover(isPresented: $showVoiceInput) {
            VoiceInputView()
        }
    }

    private var isThinking: Bool {
        session.terminalLines.last?.type == .thinking
    }

    private var statusColor: Color {
        switch session.sessionState.connection {
        case .connected: return Theme.Accent.success
        case .connecting: return Theme.Text.secondary
        case .disconnected: return Theme.Accent.error
        case .iPhoneUnreachable: return Theme.Accent.approval
        }
    }

    private func colorFor(_ type: TerminalLine.LineType) -> Color {
        switch type {
        case .output:   return Theme.Text.primary
        case .command:  return .white
        case .system:   return Theme.Text.secondary
        case .thinking: return Theme.Text.primary.opacity(0.5)
        case .error:    return Theme.Accent.error
        }
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

#Preview {
    SessionView()
        .environmentObject(WatchViewState.shared)
}
