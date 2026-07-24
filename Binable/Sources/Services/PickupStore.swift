import Foundation
import Combine

@MainActor
final class PickupStore: ObservableObject {

    static let shared = PickupStore()

    @Published private(set) var results: [LocationPickups] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastRefresh: Date?

    private var refreshTask: Task<Void, Never>?
    private var scheduleTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let cacheKey = "cachedPickups"
    private var cache: [UUID: CachedPickups] = [:]

    private init() {
        loadCache()
        populateFromCache()

        AppSettings.shared.$locations
            .combineLatest(AppSettings.shared.$fetchFrequency)
            .sink { [weak self] _, _ in
                self?.reschedule()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await performFetch()
        }
    }

    private func performFetch() async {
        let settings = AppSettings.shared
        guard !settings.locations.isEmpty else {
            results = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        var newResults: [LocationPickups] = []
        let apiKey = settings.apiKey.isEmpty ? nil : settings.apiKey
        let cacheSnapshot = cache

        await withTaskGroup(of: LocationPickups.self) { group in
            for loc in settings.locations {
                group.addTask {
                    do {
                        let entries = try await APIService.shared.fetchPickups(for: loc, apiKey: apiKey)
                        let upcoming = Self.upcoming(entries)
                        return LocationPickups(id: loc.id, location: loc, entries: Array(upcoming.prefix(5)), lastFetched: Date())
                    } catch {
                        // Network/server failure: fall back to the last successful result so the
                        // user always sees data, flagged as stale with the original fetch date.
                        if let cached = cacheSnapshot[loc.id] {
                            return LocationPickups(id: loc.id, location: loc, entries: Self.upcoming(cached.entries), error: error.localizedDescription, lastFetched: cached.fetchedAt, isStale: true)
                        }
                        return LocationPickups(id: loc.id, location: loc, entries: [], error: error.localizedDescription, lastFetched: nil)
                    }
                }
            }
            for await result in group {
                newResults.append(result)
            }
        }

        // Preserve original order from settings
        let order = settings.locations.map(\.id)
        results = newResults.sorted { a, b in
            let ai = order.firstIndex(of: a.id) ?? Int.max
            let bi = order.firstIndex(of: b.id) ?? Int.max
            return ai < bi
        }
        lastRefresh = Date()

        // Persist fresh successes; keep prior cache entries for failed fetches.
        for result in newResults where result.error == nil {
            cache[result.id] = CachedPickups(entries: result.entries, fetchedAt: result.lastFetched ?? Date())
        }
        let validIDs = Set(settings.locations.map(\.id))
        cache = cache.filter { validIDs.contains($0.key) }
        persistCache()
    }

    /// Upcoming (today or later) entries, sorted by date. Re-applied on cached data
    /// so stale results never surface pickups that are already in the past.
    nonisolated private static func upcoming(_ entries: [PickupEntry]) -> [PickupEntry] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return entries
            .filter { $0.parsedDate.map { $0 >= startOfToday } ?? false }
            .sorted { ($0.parsedDate ?? .distantFuture) < ($1.parsedDate ?? .distantFuture) }
    }

    // MARK: - Cache persistence

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([UUID: CachedPickups].self, from: data)
        else { return }
        cache = decoded
    }

    private func persistCache() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    /// Shows the last known pickups immediately on launch, before the first fetch completes.
    private func populateFromCache() {
        let locations = AppSettings.shared.locations
        results = locations.compactMap { loc in
            guard let cached = cache[loc.id] else { return nil }
            return LocationPickups(id: loc.id, location: loc, entries: Self.upcoming(cached.entries), lastFetched: cached.fetchedAt)
        }
    }

    private func reschedule() {
        scheduleTask?.cancel()
        scheduleTask = Task {
            while !Task.isCancelled {
                await performFetch()
                let interval = AppSettings.shared.fetchFrequency.interval
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
}
