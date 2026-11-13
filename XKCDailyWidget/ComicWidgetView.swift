import SwiftUI
import WidgetKit

struct ComicWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComicEntry

    var body: some View {
        content
            .widgetURL(entry.comic.flatMap { $0.num > 0 ? AppConfig.deepLink(for: $0.num) : nil })
            .containerBackground(for: .widget) { Theme.paper }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            if let comic = entry.comic {
                Text("xkcd: \(comic.displayTitle)")
            } else {
                Text("xkcd: offline")
            }
        case .accessoryRectangular:
            AccessoryView(entry: entry)
        case .systemSmall:
            SmallView(entry: entry)
        case .systemMedium:
            StripView(entry: entry, showsAlt: false, titleFont: .grotesk(.subheadline, weight: .bold))
                .padding(12)
        case .systemExtraLarge:
            StripView(entry: entry, showsAlt: true, altLines: 4, titleFont: .grotesk(.title2, weight: .bold))
                .padding(20)
        default:
            StripView(entry: entry, showsAlt: true, altLines: 3, titleFont: .grotesk(.headline, weight: .bold))
                .padding(16)
        }
    }
}

// MARK: - Home Screen

private struct SmallView: View {
    let entry: ComicEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(entry.comic.map { $0.num > 0 ? "#\($0.num)" : "xkcd" } ?? "xkcd")
                    .font(.mono(.caption2))
                    .foregroundStyle(Theme.inkMuted)
                Spacer(minLength: 0)
                if entry.kind == .new { NewMark() }
            }
            ComicPlate(entry: entry)
        }
        .padding(10)
    }
}

private struct StripView: View {
    let entry: ComicEntry
    var showsAlt: Bool
    var altLines: Int = 3
    var titleFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let comic = entry.comic {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if comic.num > 0 {
                        Text("#\(comic.num)")
                            .font(.mono(.caption))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    Text(comic.displayTitle)
                        .font(titleFont)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .widgetAccentable()
                    Spacer(minLength: 4)
                    if let kind = entry.kind, kind == .new { PickTag(kind: kind) }
                }
            }
            ComicPlate(entry: entry)
            if showsAlt, let comic = entry.comic {
                Text(comic.alt)
                    .font(.reading(.caption))
                    .italic()
                    .foregroundStyle(Theme.inkMuted)
                    .lineLimit(altLines)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The strip on its white plate, or a stick figure if it's missing.
private struct ComicPlate: View {
    let entry: ComicEntry

    var body: some View {
        ZStack {
            Theme.plate
            if let image = entry.image {
                comicImage(image)
                    .padding(4)
            } else {
                VStack(spacing: 4) {
                    StickFigure().frame(maxWidth: 48, maxHeight: 48)
                    if let message = entry.errorMessage {
                        Text(message)
                            .font(.grotesk(.caption2, weight: .medium))
                            .foregroundStyle(.black.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(Rectangle().strokeBorder(Theme.ruleSoft, lineWidth: Theme.hairline))
    }

    @ViewBuilder
    private func comicImage(_ image: UIImage) -> some View {
        if #available(iOS 18.0, *) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .widgetAccentedRenderingMode(.fullColor)
                .aspectRatio(contentMode: .fit)
        } else {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        }
    }
}

/// A small filled square marking a brand-new strip.
private struct NewMark: View {
    var body: some View {
        Text("NEW")
            .font(.grotesk(.caption2, weight: .bold))
            .tracking(0.6)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .foregroundStyle(Theme.onTeal)
            .background(Theme.teal)
    }
}

// MARK: - Lock Screen

private struct AccessoryView: View {
    let entry: ComicEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let comic = entry.comic {
                Text(comic.num > 0 ? "XKCD #\(comic.num)" : "XKCD")
                    .font(.mono(.caption2, weight: .semibold))
                    .widgetAccentable()
                Text(comic.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
            } else {
                Text("XKCD")
                    .font(.mono(.caption2, weight: .semibold))
                Text("Offline")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview(as: .systemMedium) {
    DailyComicWidget()
} timeline: {
    ComicEntry.placeholder
}

#Preview(as: .accessoryRectangular) {
    DailyComicWidget()
} timeline: {
    ComicEntry.placeholder
}
