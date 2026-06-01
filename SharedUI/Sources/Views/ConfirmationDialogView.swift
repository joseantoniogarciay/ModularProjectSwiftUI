import SwiftUI

/// A centered card dialog with an icon, title, message and two stacked actions — the SwiftUI
/// mirror of the UIKit `ConfirmationDialogViewController`.
///
/// Designed to be hosted in a `fullScreenCover` whose present/dismiss animation is disabled
/// (wrap the binding toggle in a `disablesAnimations` transaction) so the dim covers the whole
/// screen — nav bar included — while this view cross-dissolves its content in and out itself,
/// matching UIKit's `overFullScreen` + `.crossDissolve`. The `onConfirm`/`onCancel` callbacks
/// fire *after* the fade-out finishes, so the caller should flip the cover's binding there.
public struct ConfirmationDialogView: View {
    private let icon: String?
    private let title: String?
    private let message: String
    private let confirmTitle: String
    private let cancelTitle: String
    private let onConfirm: () -> Void
    private let onCancel: () -> Void

    /// 0 → 1 fades the whole dialog (dim + card) in on appear and back out before the
    /// callbacks dismiss the cover, producing the cross-dissolve.
    @State private var shown = false

    private static let fadeDuration: TimeInterval = 0.25

    public init(
        icon: String? = nil,
        title: String? = nil,
        message: String,
        confirmTitle: String,
        cancelTitle: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismiss(then: onCancel) }

            card
                .frame(maxWidth: 360)
                .padding(.horizontal, 24)
        }
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: Self.fadeDuration)) { shown = true }
        }
    }

    /// Fades the dialog out, then runs `action` (which dismisses the cover). The cover's own
    /// present/dismiss animation is disabled by the caller, so only this fade is visible.
    private func dismiss(then action: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: Self.fadeDuration)) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeDuration) {
            action()
        }
    }

    private var card: some View {
        VStack(spacing: 20) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .regular))
                    .frame(height: 56)
                    .foregroundStyle(SharedUIAsset.text.swiftUIColor)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(SharedUIAsset.text.swiftUIColor)
                        .accessibilityAddTraits(.isHeader)
                }
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
            }

            VStack(spacing: 12) {
                Button(confirmTitle) { dismiss(then: onConfirm) }
                    .buttonStyle(PrimaryButtonStyle())
                Button(cancelTitle) { dismiss(then: onCancel) }
                    .buttonStyle(OutlineButtonStyle())
            }
            // Base spacing is 20; the extra 4 makes the text→buttons gap 24, matching the
            // UIKit `setCustomSpacing(24, after: textStack)`.
            .padding(.top, 4)
        }
        .padding(.top, 28)
        .padding(.bottom, 20)
        .padding(.horizontal, 24)
        .background(SharedUIAsset.cardBackground.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        SharedUIAsset.background.swiftUIColor.ignoresSafeArea()
        ConfirmationDialogView(
            icon: "tray",
            title: "No products available",
            message: "There's nothing to add right now. Open the web to seed the feed.",
            confirmTitle: "Open web",
            cancelTitle: "Cancel",
            onConfirm: {},
            onCancel: {}
        )
    }
}
