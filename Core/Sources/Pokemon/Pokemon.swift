import Foundation

/// `Hashable` conformance lets `Pokemon` serve as the `NavigationLink` value in
/// `PokemonFlowView`, so `PokemonDetailView` receives the full model (including `name`)
/// the moment the user taps a row — matching UIKit's coordinator behaviour.
public struct Pokemon: Sendable, Hashable {
    public let id: Int
    public let name: String
    public let imageURL: URL?

    public init(id: Int, name: String, imageURL: URL?) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }
}
