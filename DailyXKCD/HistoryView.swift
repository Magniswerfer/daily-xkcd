import SwiftUI

/// Every day's pick so far, newest first.
struct HistoryView: View {
    @Environment(ComicModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.history.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        LabelText("No past days yet")
                        Text("Each day's comic is kept here. Come back tomorrow and today's strip will be the first entry.")
                            .font(.reading())
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    List(model.history) { entry in
                        Button {
                            dismiss()
                            Task { await model.show(number: entry.pick.number, dayKey: entry.dayKey, kind: entry.pick.kind) }
                        } label: {
                            HistoryRow(dayKey: entry.dayKey, pick: entry.pick, title: model.cachedTitle(for: entry.pick.number))
                        }
                        .listRowBackground(Theme.paper)
                        .listRowSeparatorTint(Theme.ruleSoft)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Past days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let dayKey: String
    let pick: ComicStore.Pick
    let title: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                LabelText(dateText)
                Text(title ?? "xkcd #\(pick.number)")
                    .font(.grotesk(.body, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            if pick.kind == .new { PickTag(kind: .new) }
            Text("#\(pick.number)")
                .font(.mono(.footnote))
                .foregroundStyle(Theme.inkMuted)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var dateText: String {
        guard let date = DayKey.date(from: dayKey) else { return dayKey }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
    }
}
