import Core
import SharedUI
import SwiftUI

public struct PokemonDetailView: View {
    /// The list-level model — available immediately on push, so the navigation
    /// title shows the Pokémon name before the detail request completes.
    /// This mirrors UIKit's PokemonCoordinator passing a full `Pokemon` to
    /// `PokemonDetailViewController` rather than just an id.
    let pokemon: Pokemon
    let store: PokemonStore
    /// Whether to greet the loaded Pokémon with an info banner. Only the push-notification
    /// entry point opts in; normal list navigation leaves it off.
    private let showsGreetingBanner: Bool

    public init(pokemon: Pokemon, store: PokemonStore, showsGreetingBanner: Bool = false) {
        self.pokemon = pokemon
        self.store = store
        self.showsGreetingBanner = showsGreetingBanner
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.bannerPresenter) private var bannerPresenter
    /// Used to resolve `Color`s to their RGB components for WCAG contrast — the SwiftUI-native
    /// replacement for `UIColor.getRed(...)`.
    @Environment(\.self) private var environment
    /// Scales with Dynamic Type so the illustration stays proportional at larger categories.
    @ScaledMetric(relativeTo: .body) private var spriteSize: CGFloat = 200

    private var detailState: PokemonStore.DetailState? { store.detailStates[pokemon.id] }

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
                    Task { await store.loadDetail(id: pokemon.id) }
                }
                .accessibilityIdentifier("pokemon.detail.retry")
            case .some(.loaded(let detail)):
                detailContent(detail)
            }
        }
        .navigationTitle(pokemon.name.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadDetail(id: pokemon.id)
            // SwiftUI-only flourish (no UIKit counterpart): greet the loaded Pokémon with an
            // info banner once its detail finishes loading — only when reached via push.
            guard showsGreetingBanner else { return }
            if case .loaded(let detail) = store.detailStates[pokemon.id] {
                bannerPresenter?.show(BannerPayload(
                    message: detail.name.capitalized,
                    style: .info,
                    iconSystemName: "checkmark.circle.fill"
                ))
            }
        }
    }

    // MARK: - Detail content

    @ViewBuilder
    private func detailContent(_ pokemon: PokemonDetail) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                RemoteImage(url: pokemon.imageURL)
                    .frame(width: spriteSize, height: spriteSize)
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
        VStack(spacing: 8) {
            HStack {
                Text(displayName(for: stat.name))
                    .font(.caption)
                    .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
                Spacer()
                Text("\(stat.baseValue)")
                    .font(.caption)
                    .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
            }
            ProgressView(value: Double(stat.baseValue), total: 255)
                .progressViewStyle(StatBarStyle(color: barColor(for: stat.baseValue)))
        }
        .padding(10)
        .background(cardBackground(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayName(for: stat.name)), \(stat.baseValue)")
    }

    // MARK: - Stat bar style

    /// A linear progress bar that fills left-to-right using the track and fill colors from
    /// SharedUIAsset. Encapsulates the GeometryReader so callers use the semantic ProgressView API.
    private struct StatBarStyle: ProgressViewStyle {
        let color: Color

        func makeBody(configuration: Configuration) -> some View {
            let fraction = CGFloat(configuration.fractionCompleted ?? 0)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(SharedUIAsset.statTrack.swiftUIColor)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Card background (shadow in light / border in dark)

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(SharedUIAsset.cardBackground.swiftUIColor)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.09),
                radius: 10,
                x: 0,
                y: 3
            )
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                }
            }
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
        "fire": Color(red: 0.98, green: 0.42, blue: 0.21),
        "water": Color(red: 0.24, green: 0.56, blue: 0.90),
        "grass": Color(red: 0.32, green: 0.72, blue: 0.30),
        "electric": Color(red: 0.95, green: 0.72, blue: 0.10),
        "psychic": Color(red: 0.95, green: 0.29, blue: 0.52),
        "ice": Color(red: 0.44, green: 0.74, blue: 0.83),
        "dragon": Color(red: 0.44, green: 0.20, blue: 0.95),
        "dark": Color(red: 0.44, green: 0.35, blue: 0.29),
        "fairy": Color(red: 0.90, green: 0.55, blue: 0.72),
        "fighting": Color(red: 0.75, green: 0.19, blue: 0.15),
        "poison": Color(red: 0.63, green: 0.25, blue: 0.63),
        "ground": Color(red: 0.88, green: 0.72, blue: 0.35),
        "rock": Color(red: 0.71, green: 0.63, blue: 0.37),
        "bug": Color(red: 0.59, green: 0.67, blue: 0.08),
        "ghost": Color(red: 0.44, green: 0.35, blue: 0.62),
        "steel": Color(red: 0.60, green: 0.62, blue: 0.70),
        "normal": Color(red: 0.66, green: 0.65, blue: 0.48),
        "flying": Color(red: 0.55, green: 0.53, blue: 0.90),
    ]

    func typeColor(_ type: String) -> Color {
        Self.typeColors[type.lowercased()] ?? .gray
    }

    /// WCAG relative luminance — picks black on light backgrounds, white on dark ones.
    /// Threshold 0.5 ensures readability on electric-yellow, pale-cyan, pale-pink chips.
    func contrastingTextColor(on background: Color) -> Color {
        // `Color.Resolved` exposes the linearized sRGB components directly, so we skip the
        // manual gamma-decode that the UIColor path needed.
        let resolved = background.resolve(in: environment)
        let luminance = 0.2126 * Double(resolved.linearRed)
            + 0.7152 * Double(resolved.linearGreen)
            + 0.0722 * Double(resolved.linearBlue)
        return luminance > 0.5 ? .black : .white
    }

    func barColor(for value: Int) -> Color {
        switch value {
        case ..<50:    return .red
        case 50..<80:  return .orange
        case 80..<100: return .yellow
        default:       return .green
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
            id: 25,
            name: "pikachu",
            imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"),
            types: ["electric"],
            heightDecimetres: 4,
            weightHectograms: 60,
            stats: [
                PokemonStat(name: "hp", baseValue: 35),
                PokemonStat(name: "attack", baseValue: 55),
                PokemonStat(name: "defense", baseValue: 40),
                PokemonStat(name: "special-attack", baseValue: 50),
                PokemonStat(name: "special-defense", baseValue: 50),
                PokemonStat(name: "speed", baseValue: 90),
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

private let previewPikachu = Pokemon(
    id: 25,
    name: "pikachu",
    imageURL: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png")
)

#Preview("Detail – loaded") {
    NavigationStack {
        PokemonDetailView(pokemon: previewPikachu, store: PokemonStore(repository: PreviewDetailRepository()))
    }
}

#Preview("Detail – error") {
    NavigationStack {
        PokemonDetailView(pokemon: previewPikachu, store: PokemonStore(repository: ErrorDetailRepository()))
    }
}
