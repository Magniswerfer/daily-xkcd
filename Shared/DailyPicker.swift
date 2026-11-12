import Foundation

/// Deterministic archive picks: the same day always maps to the same comic,
/// so the app and every widget agree without talking to each other.
enum DailyPicker {
    /// Comic numbers that don't exist or don't work as a static strip.
    static let excluded: Set<Int> = [404]

    static func archivePick(dayKey: String, latest: Int, avoiding recent: Set<Int>) -> Int {
        guard latest > 1 else { return max(latest, 1) }
        var rng = SplitMix64(seed: fnv1a(dayKey))
        var fallback = 1
        for attempt in 0..<64 {
            let candidate = Int(rng.next() % UInt64(latest)) + 1
            if attempt == 0 { fallback = candidate }
            if excluded.contains(candidate) { continue }
            if recent.contains(candidate) { continue }
            return candidate
        }
        return excluded.contains(fallback) ? fallback + 1 : fallback
    }

    /// The next comic to feature as "new": the one after the last featured
    /// comic, so every new strip gets its own day even if the app wasn't
    /// opened for a while. On first launch, the latest comic.
    static func nextNewComic(lastFeatured: Int, latest: Int) -> Int? {
        guard lastFeatured > 0 else { return latest }
        var n = lastFeatured + 1
        while excluded.contains(n) { n += 1 }
        return n <= latest ? n : nil
    }

    private static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    private struct SplitMix64 {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }
}
