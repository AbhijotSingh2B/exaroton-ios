import SwiftUI

// MARK: - Liquid Glass Card
// Uses native GlassEffectContainer on iOS 26+
// Falls back to ultraThinMaterial + rounded rect on iOS 17–25

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var padding: CGFloat
    var content: () -> Content

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer {
                content()
                    .padding(padding)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content()
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Effect (Loading State)

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .white.opacity(0.3), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
