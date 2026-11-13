import SwiftUI
import WidgetKit

@main
struct XKCDailyWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyComicWidget()
    }
}

struct DailyComicWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.widgetKind, provider: ComicProvider()) { entry in
            ComicWidgetView(entry: entry)
        }
        .configurationDisplayName("xkcdaily")
        .description("Today's xkcd strip, refreshed every day at midnight.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
            .accessoryRectangular, .accessoryInline,
        ])
        .contentMarginsDisabled()
    }
}
