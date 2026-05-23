import Core
import SharedUI
import SwiftUI

public struct PokemonDetailView: View {
    let pokemonID: Int
    var store: PokemonStore   // shared instance from PokemonListView

    private var detailState: PokemonStore.DetailState? { store.detailStates[pokemonID] }

    public var body: some View {
        Group {
            switch detailState {
            case .none:
                LoadingView()
            case .some(.loading):
                LoadingView()
            case .some(.error(let error)):
                RetryView(message: detailErrorMessage(error)) {
                    Task { await store.loadDetail(id: pokemonID) }
                }
            case .some(.loaded(let detail)):
                detailContent(detail)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadDetail(id: pokemonID) }
    }

    @ViewBuilder
    private func detailContent(_ pokemon: PokemonDetail) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                RemoteImage(url: pokemon.imageURL)
                    .frame(width: 200, height: 200)

                HStack(spacing: 8) {
                    ForEach(pokemon.types, id: \.self) { type in
                        Text(type.capitalized)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(typeColor(type).opacity(0.15))
                            .foregroundStyle(typeColor(type))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 40) {
                    physicalStat(
                        value: String(format: "%.1f m", Double(pokemon.heightDecimetres) / 10),
                        label: "Height"
                    )
                    physicalStat(
                        value: String(format: "%.1f kg", Double(pokemon.weightHectograms) / 10),
                        label: "Weight"
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Base Stats")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(pokemon.stats, id: \.name) { stat in
                        HStack {
                            Text(stat.name.capitalized)
                                .font(.subheadline)
                                .frame(width: 110, alignment: .leading)
                            ProgressView(value: Double(stat.baseValue), total: 255)
                                .tint(statColor(stat.baseValue))
                            Text("\(stat.baseValue)")
                                .font(.subheadline.monospacedDigit())
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func physicalStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var navigationTitle: String {
        if case .some(.loaded(let d)) = detailState { return d.name.capitalized }
        return "Pokémon"
    }

    private func detailErrorMessage(_ error: PokemonDetailError) -> String {
        switch error {
        case .noConnection: return "No internet connection."
        case .unknown: return "Something went wrong."
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "fire": return .orange
        case "water": return .blue
        case "grass": return .green
        case "electric": return .yellow
        case "psychic", "fairy": return .pink
        case "ice": return .cyan
        case "dragon": return .indigo
        case "dark", "ground", "rock": return .brown
        case "fighting": return .red
        case "poison", "ghost": return .purple
        case "flying": return .mint
        case "steel": return Color(.systemGray)
        default: return Color(.systemGray2)
        }
    }

    private func statColor(_ value: Int) -> Color {
        switch value {
        case 0..<50: return .red
        case 50..<80: return .orange
        case 80..<100: return .yellow
        default: return .green
        }
    }
}
