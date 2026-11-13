import SwiftUI

struct RootView: View {
    @Environment(ComicModel.self) private var model
    @State private var showingHistory = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            content
                .background(Theme.paper.ignoresSafeArea())
                .navigationTitle("xkcdaily")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Theme.paper, for: .navigationBar)
                .toolbar { toolbar }
        }
        .sheet(isPresented: $showingHistory) { HistoryView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .task { await model.loadToday() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            LoadingView()
        case .failed(let message):
            ErrorView(message: message) { Task { await model.loadToday() } }
        case .loaded:
            if let displayed = model.displayed {
                ComicScreen(displayed: displayed)
            } else {
                LoadingView()
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !model.isShowingToday {
                Button {
                    Task { await model.showToday() }
                } label: {
                    Label("Today", systemImage: "chevron.backward")
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                Task { await model.showRandom() }
            } label: {
                Label("Random comic", systemImage: "shuffle")
            }
            Button {
                showingHistory = true
            } label: {
                Label("Past days", systemImage: "calendar")
            }
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            StickFigure()
                .frame(width: 72, height: 72)
                .padding(12)
                .background(Theme.plate)
                .overlay(Rectangle().strokeBorder(Theme.ruleSoft, lineWidth: Theme.hairline))
            LabelText("Fetching today's comic")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabelText("Nothing to show yet", color: Theme.error)
            Text(message)
                .font(.reading())
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again", action: retry)
                .buttonStyle(InkButtonStyle(prominent: true))
        }
        .padding(20)
        .frame(maxWidth: 420, alignment: .leading)
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.error).frame(width: Theme.rule)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
