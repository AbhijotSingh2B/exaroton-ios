import SwiftUI

// MARK: - Server Card

struct ServerCardView: View {

    let server: ExarotonServer
    @State private var isBreathing = false

    private var statusTint: Color {
        switch server.status {
        case .online: return Color(red: 0.2, green: 0.9, blue: 0.45)
        case .offline, .crashed: return Color(red: 1.0, green: 0.3, blue: 0.3)
        default: return Color(red: 0.3, green: 0.7, blue: 1.0)
        }
    }

    var body: some View {
        GlassCard(cornerRadius: 22, padding: 0) {
            ZStack {
                // Dynamic faint background tint
                LinearGradient(
                    colors: [statusTint.opacity(0.04), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(alignment: .leading, spacing: 0) {

                // Top: Server name + status
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(server.name)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .tracking(0.5)

                        Text(server.address)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    Spacer()

                    StatusBadge(status: server.status)
                        .statusGlow(server.status)
                        .scaleEffect(server.status.isOnline && isBreathing ? 1.05 : 1.0)
                        .opacity(server.status.isOnline && isBreathing ? 0.8 : 1.0)
                }
                .padding(18)

                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.horizontal, 18)

                // Bottom: Player count + software
                HStack(spacing: 20) {
                    // Players
                    Label {
                        Text("\(server.players.count)/\(server.players.max)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    } icon: {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(Color(red: 0.3, green: 0.8, blue: 1.0))
                            .font(.system(size: 12))
                    }

                    // Software
                    if let sw = server.software {
                        Label {
                            Text("\(sw.name) \(sw.version)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "cube.fill")
                                .foregroundStyle(Color(red: 0.7, green: 0.5, blue: 1.0))
                                .font(.system(size: 12))
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            } // close VStack
        } // close ZStack
        } // close GlassCard
        .onAppear {
            if server.status.isOnline {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
        }
        .onChange(of: server.status) { _, newStatus in
            if newStatus.isOnline {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            } else {
                withAnimation { isBreathing = false }
            }
        }
    }
}
