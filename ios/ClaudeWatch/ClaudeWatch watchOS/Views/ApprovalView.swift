import SwiftUI
import WatchKit

struct ApprovalView: View {
    @EnvironmentObject private var session: WatchViewState
    @Environment(\.dismiss) private var dismiss

    let request: ApprovalRequest

    @State private var hasResponded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Question: "Do you want to make this edit to file.swift?"
                Text("Do you want to \(request.toolName.lowercased())?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                // File/action detail
                Text(request.actionSummary)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.Accent.approval)
                    .lineLimit(3)

                Divider().background(Theme.Text.dimmed)

                // Option 1: Yes
                Button {
                    respond(approved: true)
                } label: {
                    HStack(spacing: 6) {
                        Text("1.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Theme.Text.secondary)
                        Text("Yes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(Theme.Accent.success.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.Accent.success.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasResponded)

                // Option 2: Yes, allow all
                Button {
                    respond(approved: true, allowAll: true)
                } label: {
                    HStack(spacing: 6) {
                        Text("2.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Theme.Text.secondary)
                        Text("Yes, allow all")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(Theme.Text.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.Text.primary.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasResponded)

                // Option 3: No
                Button {
                    respond(approved: false)
                } label: {
                    HStack(spacing: 6) {
                        Text("3.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Theme.Text.secondary)
                        Text("No")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(Theme.Accent.error.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.Accent.error.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasResponded)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
        .background(Theme.Background.primary)
    }

    private func respond(approved: Bool, allowAll: Bool = false) {
        guard !hasResponded else { return }
        hasResponded = true

        WKInterfaceDevice.current().play(approved ? .success : .failure)
        session.respondToPermission(approved: approved)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

#Preview {
    ApprovalView(
        request: ApprovalRequest(toolName: "Edit", actionSummary: "Edit index.css")
    )
    .environmentObject(WatchViewState.shared)
}
