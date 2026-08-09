import SwiftUI

// MARK: - Server Card

struct ServerCardView: View {

    let server: ExarotonServer
    @State private var pressed = false

    var body: some View {
        GlassCard(cornerRadius: 22, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {

                // Top: Server name + status
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(server.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(server.address)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }

                    Spacer()

                    StatusBadge(status: server.status)
                        .statusGlow(server.status)
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
            }
        }
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(duration: 0.25, bounce: 0.3), value: pressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { p in pressed = p }, perform: {})
    }
}
