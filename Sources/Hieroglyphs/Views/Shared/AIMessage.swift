import SwiftUI

/// Animated gradient foreground modifier for AI-related UI elements.
///
/// Creates a rotating angular gradient effect that respects accessibility settings.
/// Ported from TakeNote's MovingGradientForeground pattern.
struct MovingGradientForeground: ViewModifier {
    var colors: [Color] = [.orange, .pink, .blue, .purple, .orange]
    var duration: Double = 4

    @State private var angle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                AngularGradient(
                    colors: colors,
                    center: .center,
                    angle: .degrees(angle)
                )
                .opacity(0.95)
                .allowsHitTesting(false)
            )
            .mask(content)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    angle = 360
                }
            }
    }
}

extension View {
    /// Apply animated AI gradient foreground to any view.
    ///
    /// - Parameters:
    ///   - colors: Gradient colors (defaults to orange/pink/blue/purple)
    ///   - duration: Rotation duration in seconds (defaults to 4)
    /// - Returns: View with animated gradient applied
    func animatedAIGradient(
        colors: [Color] = [.orange, .pink, .blue, .purple, .orange],
        duration: Double = 4
    ) -> some View {
        modifier(MovingGradientForeground(colors: colors, duration: duration))
    }
}

/// Apple Intelligence shimmer view for on-device AI operations.
///
/// Displays the apple.intelligence SF Symbol with animated gradient and symbol
/// effects (bounce and rotate). Used to communicate that on-device AI is working.
struct AIMessage: View {
    var message: String = "Generating..."
    var font: Font = .body

    private var label: some View {
        Label {
            Text(message)
                .font(font)
                .lineLimit(2)
                .truncationMode(.tail)
        } icon: {
            Image(systemName: "apple.intelligence")
                .symbolRenderingMode(.hierarchical)
        }
        .symbolEffect(.bounce.down)
        .symbolEffect(.rotate)
    }

    var body: some View {
        label
            .animatedAIGradient()
    }
}
