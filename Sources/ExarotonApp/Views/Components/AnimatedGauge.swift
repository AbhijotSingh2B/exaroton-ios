import SwiftUI

// MARK: - Animated Ring Gauge

struct AnimatedGauge: View {
    let value: Double       // 0.0 – 1.0
    let label: String
    let sublabel: String
    var size: CGFloat = 120
    var lineWidth: CGFloat = 10

    @State private var animatedValue: Double = 0

    var gaugeColor: Color {
        switch value {
        case 0..<0.6: return Color(red: 0.2, green: 0.85, blue: 0.45)
        case 0.6..<0.8: return Color(red: 1.0, green: 0.75, blue: 0.2)
        default: return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Value ring
            Circle()
                .trim(from: 0, to: animatedValue)
                .stroke(
                    LinearGradient(
                        colors: [gaugeColor.opacity(0.7), gaugeColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6, bounce: 0.1), value: animatedValue)

            // Center text
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(sublabel)
                    .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .onAppear {
            animatedValue = value
        }
        .onChange(of: value) { _, newVal in
            animatedValue = newVal
        }
    }
}

// MARK: - TPS Gauge (20 TPS = green, <15 = yellow, <10 = red)

struct TPSGauge: View {
    let averageTickTime: Double // in ms, 50ms = 20 TPS

    var tps: Double { min(20, 1000 / max(averageTickTime, 1)) }
    var normalized: Double { tps / 20.0 }

    var body: some View {
        AnimatedGauge(
            value: normalized,
            label: String(format: "%.1f", tps),
            sublabel: "TPS"
        )
    }
}

#Preview {
    HStack(spacing: 30) {
        AnimatedGauge(value: 0.38, label: "38%", sublabel: "RAM")
        AnimatedGauge(value: 0.73, label: "73%", sublabel: "RAM")
        AnimatedGauge(value: 0.95, label: "95%", sublabel: "RAM")
        TPSGauge(averageTickTime: 12)
    }
    .padding()
    .background(.black)
}
