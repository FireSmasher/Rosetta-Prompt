import SwiftUI

// MARK: - Cyberpunk theme
//
// Night-city violet with hot pink, acid yellow and cyan. Text uses the system text styles rather
// than fixed point sizes, and the muted colour is checked against the panel for contrast, so the
// window reads at the user's own text size.

enum Cyber {
    static let bg = Color(red: 0.043, green: 0.024, blue: 0.078)       // #0B0614
    static let panel = Color(red: 0.082, green: 0.043, blue: 0.141)    // #150B24
    static let raise = Color(red: 0.118, green: 0.063, blue: 0.200)    // #1E1033
    static let field = Color(red: 0.031, green: 0.020, blue: 0.055)
    static let text = Color(red: 0.957, green: 0.933, blue: 1.000)     // #F4EEFF
    static let mute = Color(red: 0.725, green: 0.667, blue: 0.820)     // lifted from #A99BC4 for contrast
    static let pink = Color(red: 1.000, green: 0.165, blue: 0.427)     // #FF2A6D
    static let yellow = Color(red: 0.988, green: 0.933, blue: 0.039)   // #FCEE0A
    static let cyan = Color(red: 0.020, green: 0.851, blue: 0.910)     // #05D9E8
    static let ok = Color(red: 0.20, green: 0.92, blue: 0.55)

    /// Display face. Rajdhani when the machine has it, the system font otherwise.
    static func title(_ size: CGFloat) -> Font {
        .custom("Rajdhani-Bold", size: size, relativeTo: .title)
    }
}

/// A slanted label shape, the shape of the Translate button in the design.
struct Slant: Shape {
    var skew: CGFloat = 10
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + skew, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - skew, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct CyberButtonStyle: ButtonStyle {
    var tint: Color = Cyber.pink
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = filled ? AnyShape(Slant()) : AnyShape(RoundedRectangle(cornerRadius: 6))
        configuration.label
            .font(.callout.weight(.bold))
            .foregroundStyle(filled ? Cyber.bg : Cyber.text)
            .padding(.horizontal, filled ? 22 : 10)
            .padding(.vertical, filled ? 8 : 4)
            .background(shape.fill(filled ? tint : tint.opacity(0.12)))
            .overlay(shape.stroke(tint.opacity(filled ? 0 : 0.6), lineWidth: 1))
            .shadow(color: tint.opacity(filled ? 0.7 : 0.25), radius: filled ? 8 : 3)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Scanlines over the whole window, plus a slow bright band sweeping down it. Always running.
struct ScanOverlay: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: Motion.reduced)) { timeline in
            let t = Motion.reduced ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                var y: CGFloat = 0
                while y < size.height {
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(Color.white.opacity(0.035)))
                    y += 3
                }
                let band: CGFloat = 140
                let travel = size.height + band * 2
                let top = CGFloat((t * 70).truncatingRemainder(dividingBy: Double(travel))) - band
                let gradient = Gradient(colors: [Cyber.pink.opacity(0), Cyber.pink.opacity(0.07), Cyber.pink.opacity(0)])
                ctx.fill(Path(CGRect(x: 0, y: top, width: size.width, height: band)),
                         with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: top + band)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The window title with an RGB-split glitch that fires for a moment every few seconds.
struct GlitchTitle: View {
    let text: String

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: Motion.reduced)) { timeline in
            let t = Motion.reduced ? 10 : timeline.date.timeIntervalSinceReferenceDate
            let phase = t.truncatingRemainder(dividingBy: 5.5)
            let glitching = phase < 0.22
            let jitter: CGFloat = glitching ? (Int(t * 40) % 2 == 0 ? 3 : -3) : 0
            ZStack(alignment: .leading) {
                if glitching {
                    Text(text).foregroundStyle(Cyber.cyan).offset(x: -jitter, y: 0)
                    Text(text).foregroundStyle(Cyber.yellow).offset(x: jitter, y: 1)
                }
                Text(text).foregroundStyle(Cyber.text)
            }
            .font(Cyber.title(30))
            .textCase(.uppercase)
            .tracking(2)
            .shadow(color: Cyber.pink.opacity(0.8), radius: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }
}
