import Foundation
import ImageIO
import UIKit

enum ComicError: LocalizedError {
    case badResponse(Int)
    case noImage

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "xkcd.com answered with status \(code)."
        case .noImage: return "This comic has no image to show."
        }
    }
}

/// Fetches comics and images from xkcd.com, with an on-disk cache shared with the widgets.
actor ComicService {
    static let shared = ComicService()

    private let store: ComicStore
    private let session: URLSession

    init(store: ComicStore = .shared) {
        self.store = store
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
    }

    // MARK: Comics

    func latestComic() async throws -> Comic {
        let comic = try await fetch(URL(string: "https://xkcd.com/info.0.json")!)
        store.cache(comic)
        return comic
    }

    func comic(_ number: Int) async throws -> Comic {
        if let cached = store.cachedComic(number) { return cached }
        let comic = try await fetch(URL(string: "https://xkcd.com/\(number)/info.0.json")!)
        store.cache(comic)
        return comic
    }

    /// The comic for the calendar day containing `date`, according to the current mode.
    func dailyComic(on date: Date = .now) async throws -> DailyComic {
        let key = DayKey.string(for: date)

        if store.mode == .latest {
            let latest = try await latestComic()
            return DailyComic(dayKey: key, comic: latest, kind: .latest)
        }

        if let existing = store.pick(for: key) {
            let picked = try await comic(existing.number)
            return DailyComic(dayKey: key, comic: picked, kind: existing.kind)
        }

        let latest = try await latestComic()
        let pick: ComicStore.Pick
        if let fresh = DailyPicker.nextNewComic(lastFeatured: store.lastFeaturedNew, latest: latest.num) {
            pick = .init(number: fresh, kind: .new)
        } else {
            let recent = Set(store.picks.values.map(\.number))
            pick = .init(number: DailyPicker.archivePick(dayKey: key, latest: latest.num, avoiding: recent), kind: .archive)
        }
        let stored = store.recordPick(pick, for: key)
        if stored.kind == .new { store.lastFeaturedNew = max(store.lastFeaturedNew, stored.number) }
        let picked: Comic
        if stored.number == latest.num {
            picked = latest
        } else {
            picked = try await comic(stored.number)
        }
        return DailyComic(dayKey: key, comic: picked, kind: stored.kind)
    }

    // MARK: Images

    /// Raw image bytes, from cache or network. `retina` tries the `_2x` file first.
    func imageData(for comic: Comic, retina: Bool) async throws -> Data {
        if retina, let url = comic.retinaImageURL {
            let file = store.imageURL(for: comic.num, retina: true)
            if let data = try? Data(contentsOf: file) { return data }
            if let data = try? await download(url) {
                try? data.write(to: file, options: .atomic)
                return data
            }
        }
        let file = store.imageURL(for: comic.num, retina: false)
        if let data = try? Data(contentsOf: file) { return data }
        guard let url = comic.imageURL else { throw ComicError.noImage }
        let data = try await download(url)
        try? data.write(to: file, options: .atomic)
        return data
    }

    /// Decodes an image no larger than `maxPixelSize` on its longest side.
    /// Keeps widgets well inside their memory budget.
    static func downsample(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cg)
    }

    // MARK: Networking

    private func fetch(_ url: URL) async throws -> Comic {
        try Comic.decoder.decode(Comic.self, from: try await download(url))
    }

    private func download(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ComicError.badResponse(http.statusCode)
        }
        return data
    }
}
