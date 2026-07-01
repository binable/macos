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

    private init() {
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

        await withTaskGroup(of: LocationPickups.self) { group in
            for loc in settings.locations {
                group.addTask {
                    do {
                        let entries = try await APIService.shared.fetchPickups(for: loc, apiKey: apiKey)
                        let upcoming = entries
                            .filter { $0.parsedDate.map { $0 >= Calendar.current.startOfDay(for: Date()) } ?? false }
                            .sorted { ($0.parsedDate ?? .distantFuture) < ($1.parsedDate ?? .distantFuture) }
                        return LocationPickups(id: loc.id, location: loc, entries: Array(upcoming.prefix(5)), lastFetched: Date())
                    } catch {
                        return LocationPickups(id: loc.id, location: loc, entries: [], error: error.localizedDescription, lastFetched: Date())
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
