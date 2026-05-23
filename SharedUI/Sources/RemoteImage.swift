import Kingfisher
import SwiftUI

public struct RemoteImage: View {
    private let url: URL?

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        KFImage(url)
            .placeholder { ProgressView() }
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - Preview

#Preview {
    RemoteImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"))
        .frame(width: 200, height: 200)
}
