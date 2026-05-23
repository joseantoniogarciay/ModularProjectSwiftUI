import SwiftUI

/// Full-width primary action button with an optional loading spinner.
///
/// Usage:
/// ```swift
/// Button("Log in") { action() }
///     .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
///     .disabled(isLoading)
/// ```
public struct PrimaryButtonStyle: ButtonStyle {
    public let isLoading: Bool

    public init(isLoading: Bool = false) {
        self.isLoading = isLoading
    }

    public func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .font(.body.weight(.semibold))
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.accentColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(configuration.isPressed ? 0.8 : 1)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        Button("Log in") {}
            .buttonStyle(PrimaryButtonStyle())
        Button("Logging in…") {}
            .buttonStyle(PrimaryButtonStyle(isLoading: true))
            .disabled(true)
    }
    .padding()
}
