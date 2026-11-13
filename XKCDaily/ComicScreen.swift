import SwiftUI

/// The comic on screen: number, title, the strip on its plate, the alt text and actions.
/// Stacks vertically on iPhone; on iPad the strip gets the room and the text sits beside it.
struct ComicScreen: View {
    @Environment(ComicModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass
    let displayed: ComicModel.Displayed

    @State private var zooming = false

    private var comic: Comic { displayed.comic }

    var body: some View {
        Group {
            if sizeClass == .regular {
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        plate
                            .padding(32)
                    }
                    .frame(maxWidth: .infinity)
                    Rectangle().fill(Theme.ruleSoft).frame(width: Theme.hairline)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            heading
                            altText
                            actions
                            credit
                        }
                        .padding(32)
                    }
                    .frame(width: 380)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heading
                        plate
                        altText
                        actions
                        credit
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .refreshable { await model.loadToday() }
        .fullScreenCover(isPresented: $zooming) {
            ZoomedComicView(comic: comic, image: model.image)
        }
    }

    // MARK: Parts

    private var heading: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                LabelText(dateLine)
                Spacer(minLength: 8)
                if let kind = displayed.kind { PickTag(kind: kind) }
            }
            Text("#\(comic.num)")
                .font(.mono(.subheadline))
                .foregroundStyle(Theme.inkMuted)
            Text(comic.displayTitle)
                .font(.grotesk(.largeTitle, weight: .bold))
                .tracking(-0.6)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Rectangle().fill(Theme.ink).frame(height: Theme.rule)
        }
    }

    private var plate: some View {
        Button {
            if model.image != nil { zooming = true }
        } label: {
            ZStack {
                Theme.plate
                if let image = model.image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                } else if model.imageFailed {
                    VStack(spacing: 8) {
                        StickFigure().frame(width: 56, height: 56)
                        Text("The image didn't load. Open it on xkcd.com instead.")
                            .font(.reading(.footnote))
                            .foregroundStyle(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(minHeight: 220)
                } else {
                    ProgressView()
                        .tint(.black)
                        .frame(minHeight: 220)
                }
            }
            .frame(maxWidth: .infinity)
            .overlay(Rectangle().strokeBorder(Theme.ruleSoft, lineWidth: Theme.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(comic.transcript.flatMap { $0.isEmpty ? nil : $0 } ?? "Comic: \(comic.displayTitle). \(comic.alt)")
        .accessibilityHint(Text(model.image != nil ? "Opens the comic full screen" : ""))
    }

    private var altText: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabelText("Alt text")
            Text(comic.alt)
                .font(.reading())
                .italic()
                .lineSpacing(4)
                .foregroundStyle(Theme.ink)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.paperSunken)
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { actionButtons }
            VStack(alignment: .leading, spacing: 8) { actionButtons }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Link(destination: comic.pageURL) {
            Label("xkcd.com", systemImage: "safari")
        }
        .buttonStyle(InkButtonStyle(prominent: true))

        ShareLink(item: comic.pageURL, subject: Text(comic.displayTitle), message: Text("xkcd #\(comic.num): \(comic.displayTitle)")) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(InkButtonStyle())

        Link(destination: comic.explainURL) {
            Label("Explain", systemImage: "questionmark.bubble")
        }
        .buttonStyle(InkButtonStyle())
    }

    private var credit: some View {
        Text("Comic by Randall Munroe, xkcd.com, CC BY-NC 2.5.")
            .font(.grotesk(.caption))
            .foregroundStyle(Theme.inkFaint)
    }

    private var dateLine: String {
        let dayDate = displayed.dayKey.flatMap { DayKey.date(from: $0) }
        if let dayDate {
            if Calendar.current.isDateInToday(dayDate) { return "Today · " + dayDate.formatted(.dateTime.weekday(.wide).day().month(.wide)) }
            return dayDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
        }
        if let published = comic.publishedDate {
            return "Published " + published.formatted(.dateTime.day().month(.wide).year())
        }
        return "xkcd"
    }
}

/// Square, flat buttons: filled ink for the one primary action, hairline outline otherwise.
struct InkButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.grotesk(.subheadline, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(prominent ? Theme.inkInverse : Theme.ink)
            .background(prominent ? Theme.ink : Theme.paper)
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.hairline))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
