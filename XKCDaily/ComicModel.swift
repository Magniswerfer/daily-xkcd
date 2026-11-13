import Observation
import SwiftUI
import UIKit
import WidgetKit

/// App state: today's comic, whatever comic is on screen, and the settings.
@MainActor
@Observable
final class ComicModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    struct Displayed: Equatable {
        let comic: Comic
        /// Non-nil when this is the comic of a particular day.
        let dayKey: String?
        let kind: PickKind?
    }

    private(set) var phase: Phase = .loading
    private(set) var today: DailyComic?
    private(set) var displayed: Displayed?
    private(set) var image: UIImage?
    private(set) var imageFailed = false

    private(set) var mode: ComicMode

    func setMode(_ newMode: ComicMode) {
        guard newMode != mode else { return }
        mode = newMode
        store.mode = newMode
        WidgetCenter.shared.reloadAllTimelines()
        Task { await loadToday() }
    }

    private let service: ComicService
    private let store: ComicStore
    private var loadedDayKey: String?
    private var isLoadingToday = false

    init(service: ComicService = .shared, store: ComicStore = .shared) {
        self.service = service
        self.store = store
        self.mode = store.mode
    }

    var isShowingToday: Bool {
        guard let today, let displayed else { return true }
        return displayed.comic.num == today.comic.num && displayed.dayKey == today.dayKey
    }

    /// Recorded daily picks, newest first.
    var history: [HistoryEntry] {
        store.picks.sorted { $0.key > $1.key }.map { HistoryEntry(dayKey: $0.key, pick: $0.value) }
    }

    struct HistoryEntry: Identifiable {
        let dayKey: String
        let pick: ComicStore.Pick
        var id: String { dayKey }
    }

    func cachedTitle(for number: Int) -> String? {
        store.cachedComic(number)?.displayTitle
    }

    // MARK: Loading

    func loadToday() async {
        guard !isLoadingToday else { return }
        isLoadingToday = true
        defer { isLoadingToday = false }
        if displayed == nil { phase = .loading }
        do {
            let daily = try await service.dailyComic()
            today = daily
            loadedDayKey = daily.dayKey
            await present(.init(comic: daily.comic, dayKey: daily.dayKey, kind: daily.kind))
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            if displayed == nil { phase = .failed(Self.message(for: error)) }
        }
    }

    func refreshIfDayChanged() async {
        if loadedDayKey != DayKey.string(for: .now) || today == nil {
            await loadToday()
        }
    }

    func show(number: Int, dayKey: String? = nil, kind: PickKind? = nil) async {
        if let today, today.comic.num == number, dayKey == nil || dayKey == today.dayKey {
            await present(.init(comic: today.comic, dayKey: today.dayKey, kind: today.kind))
            return
        }
        phase = .loading
        do {
            let comic = try await service.comic(number)
            await present(.init(comic: comic, dayKey: dayKey, kind: kind))
        } catch {
            phase = .failed(Self.message(for: error))
        }
    }

    func showToday() async {
        if let today {
            await present(.init(comic: today.comic, dayKey: today.dayKey, kind: today.kind))
        } else {
            await loadToday()
        }
    }

    func showRandom() async {
        let latest = today?.comic.num ?? store.lastFeaturedNew
        guard latest > 1 else { return }
        var n = Int.random(in: 1...latest)
        while DailyPicker.excluded.contains(n) { n = Int.random(in: 1...latest) }
        await show(number: n)
    }

    private func present(_ item: Displayed) async {
        let changed = displayed?.comic.num != item.comic.num
        displayed = item
        phase = .loaded
        if changed || image == nil {
            image = nil
            imageFailed = false
            await loadImage(for: item.comic)
        }
    }

    private func loadImage(for comic: Comic) async {
        do {
            let data = try await service.imageData(for: comic, retina: true)
            guard displayed?.comic.num == comic.num else { return }
            let decoded = await Task.detached(priority: .userInitiated) {
                ComicService.downsample(data, maxPixelSize: 4096)
            }.value
            image = decoded
            imageFailed = decoded == nil
        } catch {
            if displayed?.comic.num == comic.num { imageFailed = true }
        }
    }

    private static func message(for error: Error) -> String {
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return "You're offline. Today's comic will load as soon as you're back online."
        }
        return "Couldn't reach xkcd.com. \(error.localizedDescription)"
    }
}
