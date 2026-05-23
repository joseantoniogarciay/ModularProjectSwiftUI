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
