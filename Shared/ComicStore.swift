import Foundation

/// Persistent state shared between the app and the widgets through the App Group.
/// Falls back to standard defaults / the app's own caches when the group isn't
/// configured, so the app still works (widgets just won't share its state).
final class ComicStore: @unchecked Sendable {
    static let shared = ComicStore()

    struct Pick: Codable, Hashable, Sendable {
        let number: Int
        let kind: PickKind
    }

    private let defaults: UserDefaults
    let cacheDirectory: URL
    private let lock = NSLock()

    private enum Key {
        static let mode = "mode"
        static let picks = "picks"
        static let lastFeatured = "lastFeaturedNew"
    }

    init() {
        defaults = UserDefaults(suiteName: AppConfig.appGroupID) ?? .standard
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)?
            .appendingPathComponent("Library/Caches", isDirectory: true)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = base.appendingPathComponent("Comics", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: Settings

    var mode: ComicMode {
        get { defaults.string(forKey: Key.mode).flatMap(ComicMode.init(rawValue:)) ?? .daily }
        set { defaults.set(newValue.rawValue, forKey: Key.mode) }
    }

    // MARK: Daily picks

    /// Highest comic number that has been featured as "new". 0 = never.
    var lastFeaturedNew: Int {
        get { defaults.integer(forKey: Key.lastFeatured) }
        set { defaults.set(newValue, forKey: Key.lastFeatured) }
    }

    /// All recorded picks, keyed by day ("yyyy-MM-dd").
    var picks: [String: Pick] {
        lock.lock(); defer { lock.unlock() }
        guard let data = defaults.data(forKey: Key.picks),
              let decoded = try? JSONDecoder().decode([String: Pick].self, from: data) else { return [:] }
        return decoded
    }

    func pick(for dayKey: String) -> Pick? { picks[dayKey] }

    /// Records a pick unless one already exists for that day (first writer wins,
    /// so the app and widget never disagree about a day). Returns the stored pick.
    @discardableResult
    func recordPick(_ pick: Pick, for dayKey: String) -> Pick {
        lock.lock(); defer { lock.unlock() }
        var all = (defaults.data(forKey: Key.picks)).flatMap { try? JSONDecoder().decode([String: Pick].self, from: $0) } ?? [:]
        if let existing = all[dayKey] { return existing }
        all[dayKey] = pick
        // Keep roughly two years of history.
        if all.count > 730 {
            for key in all.keys.sorted().prefix(all.count - 730) { all.removeValue(forKey: key) }
        }
        if let data = try? JSONEncoder().encode(all) { defaults.set(data, forKey: Key.picks) }
        return pick
    }

    // MARK: File cache

    func metadataURL(for number: Int) -> URL {
        cacheDirectory.appendingPathComponent("\(number).json")
    }

    func imageURL(for number: Int, retina: Bool) -> URL {
        cacheDirectory.appendingPathComponent(retina ? "\(number)@2x.img" : "\(number).img")
    }

    func cachedComic(_ number: Int) -> Comic? {
        guard let data = try? Data(contentsOf: metadataURL(for: number)) else { return nil }
        return try? Comic.decoder.decode(Comic.self, from: data)
    }

    func cache(_ comic: Comic) {
        guard let data = try? Comic.encoder.encode(comic) else { return }
        try? data.write(to: metadataURL(for: comic.num), options: .atomic)
    }
}

extension Comic {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()
}

/// Calendar-day keys in the user's current time zone.
enum DayKey {
    static func string(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// Start of the next calendar day after `date`.
    static func nextMidnight(after date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86_400)
    }
}
