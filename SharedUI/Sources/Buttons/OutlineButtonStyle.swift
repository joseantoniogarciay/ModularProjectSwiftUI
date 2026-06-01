import SwiftUI

/// Bordered, transparent-fill button — the SwiftUI mirror of the UIKit `OutlineButton`.
///
/// Title in the primary text color at headline size, a 1pt border in the same color, a
/// continuous 14pt corner radius, and 0.5 opacity while pressed.
public struct OutlineButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(SharedUIAsset.text.swiftUIColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SharedUIAsset.text.swiftUIColor, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: - Preview

#Preview {
    Button("Cancel") {}
        .buttonStyle(OutlineButtonStyle())
        .padding()
}
