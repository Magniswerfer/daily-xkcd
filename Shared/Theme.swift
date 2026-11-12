import SwiftUI
import UIKit

/// Paper-and-ink palette: near-white paper, black ink, square corners,
/// hairline rules. Teal is the one section ink.
enum Theme {
    static let paper = dynamic(light: 0xFBFBFA, dark: 0x111112)
    static let paperSunken = dynamic(light: 0xF0F0ED, dark: 0x1A1A1C)
    static let ink = dynamic(light: 0x0B0B0C, dark: 0xF2F2EF)
    static let inkMuted = dynamic(light: 0x4A4A4F, dark: 0xB4B4B0)
    static let inkFaint = dynamic(light: 0x6B6B70, dark: 0x8E8E8A)
    static let inkInverse = dynamic(light: 0xFBFBFA, dark: 0x111112)
    static let ruleSoft = dynamic(light: 0xDCDCD7, dark: 0x323235)
    static let error = dynamic(light: 0xB42318, dark: 0xF0715F)

    /// Section ink for this app, with its on-colour.
    static let teal = Color(hex: 0x2F7F7A)
    static let onTeal = Color(hex: 0xFBFBFA)

    /// xkcd strips are drawn on white; they always sit on a white plate, even in dark mode.
    static let plate = Color.white

    static let hairline: CGFloat = 1
    static let rule: CGFloat = 2

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Font {
    /// Structure voice: labels, headings, controls.
    static func grotesk(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }
    /// Reading voice: alt text and explanations.
    static func reading(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .serif)
    }
    /// Numbers and measurements.
    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
}

/// Small uppercase tracked label.
struct LabelText: View {
    let text: String
    var color: Color = Theme.inkFaint

    init(_ text: String, color: Color = Theme.inkFaint) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.grotesk(.caption2, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(color)
    }
}

/// The "NEW" / "FROM THE ARCHIVE" tag. New strips get the filled teal plate;
/// archive picks get an outline, so the difference reads in greyscale too.
struct PickTag: View {
    let kind: PickKind

    var body: some View {
        Text(kind.label.uppercased())
            .font(.grotesk(.caption2, weight: .bold))
            .tracking(0.8)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundStyle(kind == .new ? Theme.onTeal : Theme.ink)
            .background(kind == .new ? Theme.teal : Color.clear)
            .overlay(Rectangle().strokeBorder(kind == .new ? Color.clear : Theme.ink, lineWidth: Theme.hairline))
    }
}

/// Simple stick figure, used as a placeholder when there's no comic image.
struct StickFigure: View {
    var body: some View {
        GeometryReader { geo in
            StickFigureShape()
                .stroke(Color.black, style: StrokeStyle(lineWidth: max(1.5, min(geo.size.width, geo.size.height) * 0.025), lineCap: .round, lineJoin: .round))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct StickFigureShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let ox = rect.minX + (rect.width - s) / 2, oy = rect.minY + (rect.height - s) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()
        path.addEllipse(in: CGRect(origin: p(0.40, 0.08), size: CGSize(width: 0.2 * s, height: 0.2 * s)))
        path.move(to: p(0.5, 0.28)); path.addLine(to: p(0.5, 0.62))
        path.move(to: p(0.5, 0.38)); path.addLine(to: p(0.32, 0.52))
        path.move(to: p(0.5, 0.38)); path.addLine(to: p(0.70, 0.30))
        path.move(to: p(0.5, 0.62)); path.addLine(to: p(0.36, 0.90))
        path.move(to: p(0.5, 0.62)); path.addLine(to: p(0.64, 0.90))
        return path
    }
}
