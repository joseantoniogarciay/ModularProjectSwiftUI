import SwiftUI

/// Underlined text link button — the SwiftUI mirror of the UIKit `TextLinkButton`.
///
/// Renders the title underlined in the primary text color at the subheadline size, and
/// dims to 0.5 opacity while pressed (matching the UIKit `isHighlighted` alpha).
///
/// Usage:
/// ```swift
/// Button("Create account") { action() }
///     .buttonStyle(TextLinkButtonStyle())
/// ```
public struct TextLinkButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .underline()
            .foregroundStyle(SharedUIAsset.text.swiftUIColor)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: - Preview

#Preview {
    Button("Create account") {}
        .buttonStyle(TextLinkButtonStyle())
        .padding()
}
