import SwiftUI

/// Claude mascot — the iconic orange sparkle/asterisk logo.
/// Drawn in code so it works on all platforms without image assets.
struct ClaudeMascot: View {
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            // The Claude logo is a rounded sparkle/asterisk shape
            // Simplified as a circle with the distinctive notch pattern
            Circle()
                .fill(Color(hex: "E87A35"))
                .frame(width: size, height: size)
                .overlay(
                    // Claude's distinctive dot pattern (simplified)
                    VStack(spacing: size * 0.08) {
                        HStack(spacing: size * 0.12) {
                            dot(size * 0.13)
                            dot(size * 0.13)
                        }
                        HStack(spacing: size * 0.22) {
                            dot(size * 0.1)
                            dot(size * 0.1)
                        }
                        dot(size * 0.11)
                    }
                    .offset(y: -size * 0.02)
                )
        }
    }

    private func dot(_ dotSize: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: dotSize, height: dotSize)
    }
}

#Preview {
    HStack(spacing: 16) {
        ClaudeMascot(size: 24)
        ClaudeMascot(size: 32)
        ClaudeMascot(size: 48)
    }
    .padding()
    .background(Color.black)
}
