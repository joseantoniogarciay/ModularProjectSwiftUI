import SwiftUI

/// Renders a remote image using the loader injected via `\.remoteImageLoader`.
/// SharedUI stays free of any concrete image library; App provides the Kingfisher-backed
/// loader, and a native `AsyncImage` fallback is used when none is injected.
public struct RemoteImage: View {
    private let url: URL?

    @Environment(\.remoteImageLoader) private var loader

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        loader.makeImage(url)
    }
}

// MARK: - Preview

#Preview {
    RemoteImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"))
        .frame(width: 200, height: 200)
}
