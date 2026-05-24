import SwiftUI

/// The banner card itself. Rendered by `BannerOverlayModifier`; not used directly by features.
struct BannerView: View {
    let payload: BannerPayload

    var body: some View {
        HStack(spacing: 12) {
            if let icon = payload.iconSystemName {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(payload.style.foregroundColor)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let title = payload.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(payload.style.foregroundColor)
                }
                Text(payload.message)
                    .font(.footnote)
                    .foregroundStyle(payload.style.secondaryForegroundColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(payload.style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BannerView(payload: BannerPayload(
            message: "Pikachu",
            style: .info,
            iconSystemName: "checkmark.circle.fill"
        ))
        BannerView(payload: BannerPayload(
            message: "Your session expired. Please log in again.",
            style: .warning,
            iconSystemName: "exclamationmark.triangle.fill"
        ))
        BannerView(payload: BannerPayload(
            message: "Could not add the item to the cart.",
            style: .error,
            iconSystemName: "xmark.circle.fill"
        ))
    }
    .padding()
}
