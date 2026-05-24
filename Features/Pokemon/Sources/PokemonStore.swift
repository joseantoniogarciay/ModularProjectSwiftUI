import Core
import Foundation
import Observation

@Observable @MainActor
public final class PokemonStore {
    // MARK: - List state

    public enum ListState { case idle, loading, loaded, error(PokemonListError) }

    public private(set) var pokemons: [Pokemon] = []
    public private(set) var listState: ListState = .idle
    public private(set) var hasMore = true
    /// Non-nil when a paginated fetch fails after the first page has already loaded.
    /// The list remains visible; only the bottom loader shows the inline retry.
    public private(set) var pageError: PokemonListError?

    // MARK: - Detail state (cached per ID)

    public enum DetailState { case loading, loaded(PokemonDetail), error(PokemonDetailError) }

    public private(set) var detailStates: [Int: DetailState] = [:]

    // MARK: - Private

    private static let pageSize = 30
    private var currentOffset = 0
    private let repository: any PokemonRepository

    public init(repository: any PokemonRepository) {
        self.repository = repository
    }

    // MARK: - List

    /// Loads the first page only if no data has been fetched yet.
    /// Use this from `.task` in list views so navigating back doesn't trigger a reload.
    /// Pull-to-refresh should call `loadFirstPage()` directly.
    public func loadPokemonsIfNeeded() async {
        guard pokemons.isEmpty, case .idle = listState else { return }
        await loadFirstPage()
    }

    public func loadFirstPage() async {
        currentOffset = 0
        pokemons = []
        hasMore = true
        pageError = nil
        listState = .loading
        await fetchNextBatch()
    }

    public func loadMoreIfNeeded(currentItem: Pokemon) async {
        guard hasMore, pageError == nil, let last = pokemons.last, last.id == currentItem.id else { return }
        guard case .loaded = listState else { return }
        await fetchNextBatch()
    }

    public func retryPage() async {
        pageError = nil
        await fetchNextBatch()
    }

    private func fetchNextBatch() async {
        listState = .loading
        do {
            let batch = try await repository.list(offset: currentOffset, limit: Self.pageSize)
            pokemons.append(contentsOf: batch)
            hasMore = batch.count == Self.pageSize
            currentOffset += batch.count
            pageError = nil
            listState = .loaded
        } catch {
            // Typed throws: `error` is already `PokemonListError` — no cast needed.
            if pokemons.isEmpty {
                listState = .error(error)
            } else {
                pageError = error
                listState = .loaded
            }
        }
    }

    // MARK: - Detail

    public func loadDetail(id: Int) async {
        if case .some(.loaded) = detailStates[id] { return }   // already cached
        detailStates[id] = .loading
        do {
            let detail = try await repository.detail(id: id)
            detailStates[id] = .loaded(detail)
        } catch {
            // Typed throws: `error` is already `PokemonDetailError` — no cast needed.
            detailStates[id] = .error(error)
        }
    }
}
