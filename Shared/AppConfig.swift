import Foundation

/// Values shared by the app and the widget extension.
enum AppConfig {
    /// App Group used to share picks, settings and cached images between the
    /// app and its widgets. Set via `APP_GROUP_ID` in Config/Signing.xcconfig,
    /// which feeds both Info.plists and both entitlements files.
    static let appGroupID: String =
        (Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String) ?? "group.com.example.dailyxkcd"

    /// URL scheme the widgets use to open a specific comic in the app.
    static let urlScheme = "dailyxkcd"

    static let widgetKind = "DailyXKCDWidget"

    static func deepLink(for number: Int) -> URL {
        URL(string: "\(urlScheme)://comic/\(number)")!
    }

    /// Parses `dailyxkcd://comic/1234` into `1234`.
    static func comicNumber(from url: URL) -> Int? {
        guard url.scheme == urlScheme, url.host == "comic" else { return nil }
        return Int(url.lastPathComponent)
    }
}
