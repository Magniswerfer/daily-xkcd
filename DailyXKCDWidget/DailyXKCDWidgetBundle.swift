import SwiftUI
import WidgetKit

@main
struct DailyXKCDWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyComicWidget()
    }
}

struct DailyComicWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.widgetKind, provider: ComicProvider()) { entry in
            ComicWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily xkcd")
        .description("Today's xkcd strip, refreshed every day at midnight.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
            .accessoryRectangular, .accessoryInline,
        ])
        .contentMarginsDisabled()
    }
}
