import Foundation

/// One xkcd comic, as described by `https://xkcd.com/<n>/info.0.json`.
struct Comic: Codable, Hashable, Identifiable, Sendable {
    let num: Int
    let title: String
    let safeTitle: String
    let alt: String
    let img: String
    let year: String
    let month: String
    let day: String
    let transcript: String?
    let link: String?

    var id: Int { num }

    var pageURL: URL { URL(string: "https://xkcd.com/\(num)/")! }
    var explainURL: URL { URL(string: "https://www.explainxkcd.com/wiki/index.php/\(num)")! }

    var imageURL: URL? {
        URL(string: img) ?? img.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed).flatMap(URL.init(string:))
    }

    /// Most comics since ~#1084 ship a double-resolution `_2x.png` next to the
    /// regular image. Not guaranteed to exist, so callers fall back to `imageURL`.
    var retinaImageURL: URL? {
        guard img.hasSuffix(".png"), !img.contains("_2x"), let base = imageURL else { return nil }
        let s = base.absoluteString
        return URL(string: String(s.dropLast(4)) + "_2x.png")
    }

    var publishedDate: Date? {
        guard let y = Int(year), let m = Int(month), let d = Int(day) else { return nil }
        return Calendar(identifier: .gregorian).date(from: DateComponents(year: y, month: m, day: d))
    }

    var displayTitle: String { safeTitle.isEmpty ? title : safeTitle }

    static let sample = Comic(
        num: 0,
        title: "xkcdaily",
        safeTitle: "xkcdaily",
        alt: "A new strip, every day.",
        img: "",
        year: "2026", month: "1", day: "1",
        transcript: nil, link: nil
    )
}

/// Why a comic is today's comic.
enum PickKind: String, Codable, Sendable {
    /// A comic xkcd published since the app last featured a new one.
    case new
    /// A deterministic pick from the archive, used on days without a new strip.
    case archive
    /// "Always show the latest" mode.
    case latest

    var label: String {
        switch self {
        case .new: return "New"
        case .archive: return "From the archive"
        case .latest: return "Latest"
        }
    }
}

/// The comic chosen for a given calendar day.
struct DailyComic: Hashable, Sendable {
    let dayKey: String
    let comic: Comic
    let kind: PickKind
}

/// How today's comic is chosen.
enum ComicMode: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Every new xkcd gets its own day; days without one get a classic from the archive.
    case daily
    /// Always show the most recently published comic.
    case latest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "A new strip every day"
        case .latest: return "Only the latest strip"
        }
    }

    var explanation: String {
        switch self {
        case .daily:
            return "Each new xkcd gets a day of its own. On the days in between, you get a different classic from the archive."
        case .latest:
            return "Always shows the newest xkcd. Randall publishes on Mondays, Wednesdays and Fridays, so most days repeat."
        }
    }
}
