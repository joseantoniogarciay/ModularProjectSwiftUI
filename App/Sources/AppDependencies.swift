import Core
import Data
import Foundation
import Networking
import Pokemon

@MainActor
final class AppDependencies {
    static let shared = AppDependencies()

    let pokemonStore: PokemonStore

    private init() {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let userAgent = "iOS/\(os.majorVersion).\(os.minorVersion) ModularSwiftUI/1.0"
        let client = AlamofireNetClient(userAgent: userAgent)
        let baseURL = URL(string: "https://pokeapi.co/api/v2")!
        let repository = PokemonRepositoryImpl(client: client, baseURL: baseURL)
        pokemonStore = PokemonStore(repository: repository)
    }
}
