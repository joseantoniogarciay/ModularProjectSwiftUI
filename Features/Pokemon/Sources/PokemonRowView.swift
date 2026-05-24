import Core
import SharedUI
import SwiftUI

struct PokemonRowView: View {
    let pokemon: Pokemon

    @Environment(\.colorScheme) private var colorScheme
    /// Scales with Dynamic Type so the sprite stays visually proportional to the name/number text.
    @ScaledMetric(relativeTo: .body) private var spriteSize: CGFloat = 72

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(url: pokemon.imageURL)
                .frame(width: spriteSize, height: spriteSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(pokemon.name.capitalized)
                    .font(.headline)
                Text(String(format: "#%03d", pokemon.id))
                    .font(.caption)
                    .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Font.caption.weight(.semibold))
                .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(SharedUIAsset.cardBackground.swiftUIColor)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.09),
                radius: 10,
                x: 0,
                y: 3
            )
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                }
            }
    }
}

// MARK: - Button style

/// Replicates UIKit PokemonCell.setHighlighted: scale 0.97 + alpha 0.75 on press.
/// Skips the transform (but keeps alpha) when Reduce Motion is enabled.
struct PokemonCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    PokemonRowView(pokemon: Pokemon(
        id: 25,
        name: "pikachu",
        imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png")
    ))
    .padding(.horizontal, 16)
    .padding(.vertical, 6)
}
