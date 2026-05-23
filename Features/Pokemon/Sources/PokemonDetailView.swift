import Core
import SharedUI
import SwiftUI
import UIKit  // for UIColor luminance calculation

public struct PokemonDetailView: View {
    let pokemonID: Int
    var store: PokemonStore

    @Environment(\.colorScheme) private var colorScheme

    private var detailState: PokemonStore.DetailState? { store.detailStates[pokemonID] }

    public var body: some View {
        Group {
            switch detailState {
            case .none:
                LoadingView()
                    .accessibilityIdentifier("pokemon.detail.loading")
            case .some(.loading):
                LoadingView()
                    .accessibilityIdentifier("pokemon.detail.loading")
            case .some(.error(let error)):
                RetryView(message: messageFor(error)) {
                    Task { await store.loadDetail(id: pokemonID) }
                }
                .accessibilityIdentifier("pokemon.detail.retry")
            case .some(.loaded(let detail)):
                detailContent(detail)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadDetail(id: pokemonID) }
    }

    // MARK: - Detail content

    @ViewBuilder
    private func detailContent(_ pokemon: PokemonDetail) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                RemoteImage(url: pokemon.imageURL)
                    .frame(width: 200, height: 200)
                    .accessibilityHidden(true)

                // Type badges — full color, WCAG text
                HStack(spacing: 8) {
                    ForEach(pokemon.types, id: \.self) { type in
                        typeBadge(type)
                    }
                }

                // Metric cards
                HStack(spacing: 12) {
                    metricCard(
                        title: "Height",
                        value: String(format: "%.1f m", Double(pokemon.heightDecimetres) / 10),
                        icon: "ruler"
                    )
                    metricCard(
                        title: "Weight",
                        value: String(format: "%.1f kg", Double(pokemon.weightHectograms) / 10),
                        icon: "scalemass"
                    )
                }

                // Stats
                VStack(alignment: .leading, spacing: 10) {
                    Text("Base Stats")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("pokemon.detail.stats-header")
                    ForEach(pokemon.stats, id: \.name) { stat in
                        statRow(stat)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .accessibilityIdentifier("pokemon.detail.scroll")
        .background(SharedUIAsset.background.swiftUIColor)
    }

    // MARK: - Type badge

    private func typeBadge(_ type: String) -> some View {
        let bg = typeColor(type)
        let fg = contrastingTextColor(on: bg)
        return Text(type.capitalized)
            .font(Font.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Metric card

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
                .imageScale(.medium)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(cardBackground(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }

    // MARK: - Stat row

    private func statRow(_ stat: PokemonStat) -> some View {
        let ratio = max(0.01, min(CGFloat(stat.baseValue) / 255.0, 1.0))
        return VStack(spacing: 8) {
            HStack {
                Text(displayName(for: stat.name))
                    .font(.caption)
                    .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
                Spacer()
                Text("\(stat.baseValue)")
                    .font(.caption)
                    .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(SharedUIAsset.statTrack.swiftUIColor)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(barColor(for: stat.baseValue))
                        .frame(width: geo.size.width * ratio)
                }
                .frame(height: 6)
            }
            .frame(height: 6)
        }
        .padding(10)
        .background(cardBackground(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayName(for: stat.name)), \(stat.baseValue)")
    }

    // MARK: - Card background (shadow in light / border in dark)

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(SharedUIAsset.cardBackground.swiftUIColor)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.09),
                radius: 10, x: 0, y: 3
            )
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                }
            }
    }

    // MARK: - Navigation title

    private var navigationTitle: String {
        if case .some(.loaded(let d)) = detailState { return d.name.capitalized }
        return "Pokémon"
    }

    // MARK: - Error message

    private func messageFor(_ error: PokemonDetailError) -> String {
        switch error {
        case .noConnection: return CoreStrings.errorNoConnection
        case .unknown:      return CoreStrings.errorGenericLoading
        }
    }
}

// MARK: - Color helpers

private extension PokemonDetailView {

    /// Exact RGB values matching the UIKit implementation for WCAG-correct contrast on type chips.
    static let typeColors: [String: Color] = [
        "fire":     Color(red: 0.98, green: 0.42, blue: 0.21),
        "water":    Color(red: 0.24, green: 0.56, blue: 0.90),
        "grass":    Color(red: 0.32, green: 0.72, blue: 0.30),
        "electric": Color(red: 0.95, green: 0.72, blue: 0.10),
        "psychic":  Color(red: 0.95, green: 0.29, blue: 0.52),
        "ice":      Color(red: 0.44, green: 0.74, blue: 0.83),
        "dragon":   Color(red: 0.44, green: 0.20, blue: 0.95),
        "dark":     Color(red: 0.44, green: 0.35, blue: 0.29),
        "fairy":    Color(red: 0.90, green: 0.55, blue: 0.72),
        "fighting": Color(red: 0.75, green: 0.19, blue: 0.15),
        "poison":   Color(red: 0.63, green: 0.25, blue: 0.63),
        "ground":   Color(red: 0.88, green: 0.72, blue: 0.35),
        "rock":     Color(red: 0.71, green: 0.63, blue: 0.37),
        "bug":      Color(red: 0.59, green: 0.67, blue: 0.08),
        "ghost":    Color(red: 0.44, green: 0.35, blue: 0.62),
        "steel":    Color(red: 0.60, green: 0.62, blue: 0.70),
        "normal":   Color(red: 0.66, green: 0.65, blue: 0.48),
        "flying":   Color(red: 0.55, green: 0.53, blue: 0.90),
    ]

    func typeColor(_ type: String) -> Color {
        Self.typeColors[type.lowercased()] ?? Color(.systemGray)
    }

    /// WCAG relative luminance — picks black on light backgrounds, white on dark ones.
    /// Threshold 0.5 ensures readability on electric-yellow, pale-cyan, pale-pink chips.
    func contrastingTextColor(on background: Color) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(background).getRed(&r, green: &g, blue: &b, alpha: &a)
        let toLinear: (CGFloat) -> CGFloat = { c in
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b)
        return luminance > 0.5 ? .black : .white
    }

    func barColor(for value: Int) -> Color {
        switch value {
        case ..<50:    return Color(.systemRed)
        case 50..<80:  return Color(.systemOrange)
        case 80..<100: return Color(.systemYellow)
        default:       return Color(.systemGreen)
        }
    }

    func displayName(for statName: String) -> String {
        switch statName {
        case "hp":              return "HP"
        case "attack":          return "Atk"
        case "defense":         return "Def"
        case "special-attack":  return "Sp. Atk"
        case "special-defense": return "Sp. Def"
        case "speed":           return "Speed"
        default: return statName.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
}

// MARK: - Previews

private struct PreviewDetailRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] { [] }

    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        PokemonDetail(
            id: 25, name: "pikachu",
            imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"),
            types: ["electric"],
            heightDecimetres: 4,
            weightHectograms: 60,
            stats: [
                PokemonStat(name: "hp",               baseValue: 35),
                PokemonStat(name: "attack",            baseValue: 55),
                PokemonStat(name: "defense",           baseValue: 40),
                PokemonStat(name: "special-attack",    baseValue: 50),
                PokemonStat(name: "special-defense",   baseValue: 50),
                PokemonStat(name: "speed",             baseValue: 90),
            ]
        )
    }
}

private struct ErrorDetailRepository: PokemonRepository {
    func list(offset: Int, limit: Int) async throws(PokemonListError) -> [Pokemon] { [] }
    func detail(id: Int) async throws(PokemonDetailError) -> PokemonDetail {
        throw PokemonDetailError.noConnection
    }
}

#Preview("Detail – loaded") {
    NavigationStack {
        PokemonDetailView(pokemonID: 25, store: PokemonStore(repository: PreviewDetailRepository()))
    }
}

#Preview("Detail – error") {
    NavigationStack {
        PokemonDetailView(pokemonID: 25, store: PokemonStore(repository: ErrorDetailRepository()))
    }
}
