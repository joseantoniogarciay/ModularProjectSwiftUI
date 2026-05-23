import SwiftUI

public struct RetryView: View {
    private let message: String
    private let action: () -> Void

    public init(message: String, action: @escaping () -> Void) {
        self.message = message
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try again", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    RetryView(message: "No internet connection.") {}
}
