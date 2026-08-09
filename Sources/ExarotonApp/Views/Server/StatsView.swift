import SwiftUI

// MARK: - Stats View (RAM + TPS)

struct StatsView: View {

    let webSocket: ServerWebSocket?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Gauges row
                HStack(spacing: 40) {
                    VStack(spacing: 12) {
                        AnimatedGauge(
                            value: (webSocket?.ramPercent ?? 0) / 100,
                            label: String(format: "%.0f%%", webSocket?.ramPercent ?? 0),
                            sublabel: "RAM",
                            size: 130,
                            lineWidth: 12
                        )
                        Text("Memory Usage")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    VStack(spacing: 12) {
                        TPSGauge(averageTickTime: webSocket?.averageTickTime ?? 0)
                        Text("Tick Speed")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                // Detailed numbers
                GlassCard(cornerRadius: 18, padding: 16) {
                    VStack(spacing: 0) {
                        statRow(
                            icon: "memorychip.fill",
                            label: "RAM Usage",
                            value: String(format: "%.1f%%", webSocket?.ramPercent ?? 0),
                            color: Color(red: 0.3, green: 0.7, blue: 1.0)
                        )
                        Divider().background(Color.white.opacity(0.06)).padding(.vertical, 8)
                        statRow(
                            icon: "clock.fill",
                            label: "Avg. Tick Time",
                            value: String(format: "%.2f ms", webSocket?.averageTickTime ?? 0),
                            color: Color(red: 0.8, green: 0.5, blue: 1.0)
                        )
                        Divider().background(Color.white.opacity(0.06)).padding(.vertical, 8)
                        statRow(
                            icon: "speedometer",
                            label: "TPS",
                            value: {
                                let tickTime = webSocket?.averageTickTime ?? 0
                                let tps = tickTime > 0 ? min(20, 1000 / tickTime) : 0
                                return String(format: "%.1f / 20", tps)
                            }(),
                            color: Color(red: 0.3, green: 1.0, blue: 0.5)
                        )
                        if let heap = webSocket?.heapUsageBytes, heap > 0 {
                            Divider().background(Color.white.opacity(0.06)).padding(.vertical, 8)
                            statRow(
                                icon: "internaldrive.fill",
                                label: "Heap Usage",
                                value: formatBytes(heap),
                                color: Color(red: 1.0, green: 0.7, blue: 0.3)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 32)
            }
        }
        .onAppear {
            webSocket?.subscribe(to: .stats)
            webSocket?.subscribe(to: .tick)
            webSocket?.subscribe(to: .heap)
        }
        .onDisappear {
            webSocket?.unsubscribe(from: .stats)
            webSocket?.unsubscribe(from: .tick)
            webSocket?.unsubscribe(from: .heap)
        }
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1024 { return String(format: "%.2f GB", mb / 1024) }
        return String(format: "%.0f MB", mb)
    }
}
