import SwiftUI
import WidgetKit

@main
struct DailyXKCDApp: App {
    @State private var model = ComicModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(Theme.ink)
                .onOpenURL { url in
                    if let number = AppConfig.comicNumber(from: url) {
                        Task { await model.show(number: number) }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    // Coming back the next day should show the next day's comic.
                    if phase == .active { Task { await model.refreshIfDayChanged() } }
                }
        }
    }
}
