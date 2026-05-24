import Kingfisher
import SharedUI
import SwiftUI

/// Kingfisher-backed remote image, injected into SharedUI's `\.remoteImageLoader` so the
/// SharedUI module never links Kingfisher (mirrors UIKit's `KingfisherImageLoader`).
struct KingfisherRemoteImage: View {
    let url: URL?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        KFImage(url)
            .placeholder { ProgressView() }
            .fade(duration: reduceMotion ? 0 : 0.25)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

extension RemoteImageLoader {
    /// Production loader backed by Kingfisher's caching + fade.
    static var kingfisher: RemoteImageLoader {
        RemoteImageLoader { url in
            KingfisherRemoteImage(url: url)
        }
    }
}
