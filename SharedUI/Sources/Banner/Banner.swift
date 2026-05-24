import SwiftUI

/// Visual style of a banner. Mirrors the `BannerStyle` cases from the UIKit project,
/// resolving the same `SharedUIAsset` colors so both apps look identical.
public enum BannerStyle: Sendable {
    case info
    case warning
    case error

    var backgroundColor: Color {
        switch self {
        case .info:    return SharedUIAsset.bannerInfoBackground.swiftUIColor
        case .warning: return SharedUIAsset.bannerWarningBackground.swiftUIColor
        case .error:   return SharedUIAsset.bannerErrorBackground.swiftUIColor
        }
    }

    var foregroundColor: Color {
        switch self {
        case .info:    return SharedUIAsset.text.swiftUIColor
        case .warning: return SharedUIAsset.bannerWarningForeground.swiftUIColor
        case .error:   return SharedUIAsset.bannerErrorForeground.swiftUIColor
        }
    }

    var secondaryForegroundColor: Color {
        switch self {
        case .info:    return SharedUIAsset.secondaryText.swiftUIColor
        case .warning: return SharedUIAsset.bannerWarningForeground.swiftUIColor.opacity(0.7)
        case .error:   return SharedUIAsset.bannerErrorForeground.swiftUIColor.opacity(0.75)
        }
    }
}

/// A banner to display. `id` gives SwiftUI a stable identity so consecutive banners
/// animate in and out as distinct elements.
public struct BannerPayload: Identifiable, Sendable {
    public let id = UUID()
    public let title: String?
    public let message: String
    public let style: BannerStyle
    public let iconSystemName: String?
    public let duration: TimeInterval

    public init(
        title: String? = nil,
        message: String,
        style: BannerStyle = .info,
        iconSystemName: String? = nil,
        duration: TimeInterval = 4
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.iconSystemName = iconSystemName
        self.duration = duration
    }
}
