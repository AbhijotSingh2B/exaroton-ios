import SwiftUI

// MARK: - Status Badge

struct StatusBadge: View {
    let status: ServerStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(color.opacity(0.4))
                        .frame(width: 14, height: 14)
                        .scaleEffect(status.isOnline ? pulseScale : 1)
                        .animation(
                            status.isOnline
                            ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            : .default,
                            value: pulseScale
                        )
                )

            if !compact {
                Text(status.description)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .onAppear { pulseScale = status.isOnline ? 1.6 : 1 }
    }

    @State private var pulseScale: CGFloat = 1

    private var color: Color {
        switch status {
        case .online:                       return Color(red: 0.2, green: 0.9, blue: 0.45)
        case .offline:                      return Color(white: 0.5)
        case .crashed:                      return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .starting, .loading, .pending, .preparing:
            return Color(red: 0.3, green: 0.7, blue: 1.0)
        case .stopping, .saving:            return Color(red: 1.0, green: 0.7, blue: 0.2)
        case .restarting:                   return Color(red: 0.8, green: 0.4, blue: 1.0)
        case .transferring:                 return Color(red: 0.3, green: 0.8, blue: 0.9)
        }
    }
}

// MARK: - Status Glow Modifier

extension View {
    func statusGlow(_ status: ServerStatus) -> some View {
        self.shadow(
            color: status.isOnline ? Color(red: 0.2, green: 0.9, blue: 0.45).opacity(0.5) : .clear,
            radius: 12,
            x: 0,
            y: 0
        )
    }
}

#Preview {
    HStack(spacing: 20) {
        StatusBadge(status: .online)
        StatusBadge(status: .offline)
        StatusBadge(status: .crashed)
        StatusBadge(status: .starting)
    }
    .padding()
    .background(.black)
}
