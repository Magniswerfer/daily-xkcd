# Daily xkcd

An iPhone and iPad app that shows a new xkcd strip every day, plus Home Screen
and Lock Screen widgets that show the same strip.

## What it does

- **A new strip every day.** Each new xkcd gets a day of its own (marked *New*).
  xkcd posts on Mondays, Wednesdays and Fridays, so on the days in between you
  get a different classic from the archive. The archive pick is seeded by the
  date, and the first pick made for a day is the one that's kept, so the app
  and every widget always show the same comic. You can switch to *Only the latest
  strip* in Settings.
- **Widgets:** small, medium, large and extra large (iPad) for the Home Screen,
  plus rectangular and inline widgets for the Lock Screen. They switch to the
  next comic just after midnight. Tapping a widget opens that comic in the app.
- **The app:** shows the comic number, title, the strip (tap it to open full
  screen with pinch-to-zoom), the alt text, and buttons to open the comic on
  xkcd.com, share it, or open its explainxkcd page. On iPad the strip and the
  text sit side by side. *Past days* lists every earlier daily pick, and the
  shuffle button shows a random comic.
- Comics and images are cached in a shared App Group container, so widgets load
  quickly and the app works offline for comics it has already loaded.

## Requirements

- Xcode 16 or later
- iOS / iPadOS 17 or later

## Build and run

1. Open `DailyXKCD.xcodeproj`.
2. Edit `Config/Signing.xcconfig`:
   - `DEVELOPMENT_TEAM`: your team ID
   - `BUNDLE_ID_PREFIX`: a reverse-DNS prefix you own (e.g. `com.yourname`)

   The bundle IDs and the App Group (`group.<prefix>.dailyxkcd`) are derived
   from the prefix, and the app reads the group name from its Info.plist, so
   you don't need to change anything else. With automatic signing, Xcode
   registers the App Group the first time you build for a device.
3. Select the **DailyXKCD** scheme and run it on a simulator or device.
4. To try the widgets, add **Daily xkcd** from the widget gallery, or run the
   **DailyXKCDWidgetExtension** scheme.

## Project layout

| Folder | Contents |
| --- | --- |
| `Shared/` | Code built into both targets: the comic model, the xkcd client and image cache (`ComicService`), the daily pick logic (`DailyPicker`), shared storage (`ComicStore`) and the theme |
| `DailyXKCD/` | The SwiftUI app |
| `DailyXKCDWidget/` | The WidgetKit extension |
| `Config/` | Signing settings, entitlements and Info.plist fragments |

The project uses Xcode's folder-synchronised groups, so new files you add to
these folders are picked up without editing the project file.

## Credits

xkcd is drawn by Randall Munroe and shared under a
[Creative Commons Attribution-NonCommercial 2.5](https://xkcd.com/license.html)
licence. This is an unofficial reader and isn't affiliated with xkcd. The comic
data comes from xkcd's public JSON API (`https://xkcd.com/info.0.json`).
