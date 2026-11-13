import SwiftUI

struct SettingsView: View {
    @Environment(ComicModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        LabelText("Today's comic")
                        ForEach(ComicMode.allCases) { mode in
                            ModeRow(mode: mode, selected: model.mode == mode) {
                                model.setMode(mode)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        LabelText("Widgets")
                        Text("Long-press your Home Screen or Lock Screen, tap Edit, then Add Widget and search for xkcdaily. Widgets show the same comic as the app and switch to the next one at midnight.")
                            .font(.reading())
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        LabelText("About")
                        Text("xkcd is drawn by Randall Munroe and shared under a Creative Commons Attribution-NonCommercial 2.5 licence. This app is an unofficial reader and isn't affiliated with xkcd.")
                            .font(.reading())
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Link("xkcd.com/license.html", destination: URL(string: "https://xkcd.com/license.html")!)
                            .font(.mono(.footnote))
                            .foregroundStyle(Theme.ink)
                            .underline()
                    }
                }
                .padding(20)
                .frame(maxWidth: 560, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// A selectable option. Selection is drawn with the 2px rule and a check,
/// not just colour.
private struct ModeRow: View {
    let mode: ComicMode
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(Theme.ink)
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.title)
                        .font(.grotesk(.headline, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(mode.explanation)
                        .font(.reading(.subheadline))
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                Rectangle().strokeBorder(selected ? Theme.ink : Theme.ruleSoft, lineWidth: selected ? Theme.rule : Theme.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
