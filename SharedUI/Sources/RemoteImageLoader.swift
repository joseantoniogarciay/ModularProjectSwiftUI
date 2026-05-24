import SwiftUI

/// Abstraction for rendering a remote image. The concrete loading/caching strategy is
/// injected from the App layer via `\.remoteImageLoader`, so SharedUI carries no
/// third-party image dependency — Kingfisher lives only in App, mirroring the UIKit
/// `ImageLoader` inversion.
public struct RemoteImageLoader: Sendable {
    let makeImage: @Sendable (URL?) -> AnyView

    public init<Content: View>(@ViewBuilder makeImage: @escaping @Sendable (URL?) -> Content) {
        self.makeImage = { url in AnyView(makeImage(url)) }
    }
}

private struct RemoteImageLoaderKey: EnvironmentKey {
    /// Native fallback so previews and tests render without any injected provider.
    static let defaultValue = RemoteImageLoader { url in
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fit)
            case .empty:
                ProgressView()
            case .failure:
                Color.clear
            @unknown default:
                Color.clear
            }
        }
    }
}

public extension EnvironmentValues {
    var remoteImageLoader: RemoteImageLoader {
        get { self[RemoteImageLoaderKey.self] }
        set { self[RemoteImageLoaderKey.self] = newValue }
    }
}
