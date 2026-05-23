import SwiftUI

public struct LoadingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(SharedUIStrings.loadingLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    LoadingView()
}
