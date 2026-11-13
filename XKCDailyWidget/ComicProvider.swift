import SwiftUI
import UIKit
import WidgetKit

struct ComicEntry: TimelineEntry {
    let date: Date
    let comic: Comic?
    let kind: PickKind?
    let image: UIImage?
    let errorMessage: String?

    static let placeholder = ComicEntry(date: .now, comic: .sample, kind: .new, image: nil, errorMessage: nil)
}

struct ComicProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComicEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (ComicEntry) -> Void) {
        Task {
            let entry = await makeEntry(for: context)
            completion(entry.comic == nil && context.isPreview ? .placeholder : entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComicEntry>) -> Void) {
        Task {
            let now = Date.now
            let entry = await makeEntry(for: context)
            let nextRefresh: Date
            if entry.comic == nil {
                // Offline or xkcd.com unreachable: try again soon.
                nextRefresh = now.addingTimeInterval(30 * 60)
            } else if ComicStore.shared.mode == .latest {
                nextRefresh = min(DayKey.nextMidnight(after: now), now.addingTimeInterval(3 * 60 * 60))
            } else {
                // A couple of minutes past midnight, so the new day has definitely started.
                nextRefresh = DayKey.nextMidnight(after: now).addingTimeInterval(2 * 60)
            }
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func makeEntry(for context: Context) async -> ComicEntry {
        do {
            let daily = try await ComicService.shared.dailyComic()
            var image: UIImage?
            if Self.showsImage(context.family) {
                let retina = context.family != .systemSmall
                if let data = try? await ComicService.shared.imageData(for: daily.comic, retina: retina) {
                    let longest = max(context.displaySize.width, context.displaySize.height)
                    image = ComicService.downsample(data, maxPixelSize: min(1600, max(400, longest * 3)))
                }
            }
            return ComicEntry(date: .now, comic: daily.comic, kind: daily.kind, image: image, errorMessage: nil)
        } catch {
            return ComicEntry(date: .now, comic: nil, kind: nil, image: nil, errorMessage: "Couldn't reach xkcd.com")
        }
    }

    private static func showsImage(_ family: WidgetFamily) -> Bool {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge: return true
        default: return false
        }
    }
}
