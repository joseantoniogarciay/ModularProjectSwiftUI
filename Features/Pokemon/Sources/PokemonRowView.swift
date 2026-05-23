import Core
import SharedUI
import SwiftUI

struct PokemonRowView: View {
    let pokemon: Pokemon

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: pokemon.imageURL)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(pokemon.name.capitalized)
                    .font(.headline)
                Text("#\(pokemon.id)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    PokemonRowView(pokemon: Pokemon(
        id: 25,
        name: "pikachu",
        imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png")
    ))
    .padding()
}
