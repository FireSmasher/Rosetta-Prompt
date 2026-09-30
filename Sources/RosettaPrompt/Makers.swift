import SwiftUI
import AppKit

// MARK: - Makers
//
// Every target belongs to the company that makes it, and the company's own site is the one place
// its product really runs. The app groups targets by maker, links each group to the maker's real
// website, and opens that site for a finished rewrite. `hosts` is the allowlist the self test holds
// every source link to: a link to anything but the maker's own domains is reported as a failure.

enum Maker: String, CaseIterable, Identifiable {
    case anthropic, openai, google, undermind

    var id: String { rawValue }

    var name: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .openai: return "OpenAI"
        case .google: return "Google"
        case .undermind: return "Undermind"
        }
    }

    /// The maker's own home page, opened from the group header.
    var homepage: URL {
        switch self {
        case .anthropic: return URL(string: "https://www.anthropic.com")!
        case .openai: return URL(string: "https://openai.com")!
        case .google: return URL(string: "https://deepmind.google")!
        case .undermind: return URL(string: "https://www.undermind.ai")!
        }
    }

    /// Where the maker's model or product actually runs for a person, opened with a finished rewrite.
    var workspace: URL {
        switch self {
        case .anthropic: return URL(string: "https://claude.ai/new")!
        case .openai: return URL(string: "https://chatgpt.com/")!
        case .google: return URL(string: "https://gemini.google.com/app")!
        case .undermind: return URL(string: "https://www.undermind.ai/")!
        }
    }

    var workspaceName: String {
        switch self {
        case .anthropic: return "Claude"
        case .openai: return "ChatGPT"
        case .google: return "Gemini"
        case .undermind: return "Undermind"
        }
    }

    /// Domains the maker publishes under. Every source link of every target must land on one.
    var hosts: [String] {
        switch self {
        case .anthropic: return ["platform.claude.com", "support.claude.com", "docs.claude.com", "claude.ai", "anthropic.com", "www.anthropic.com"]
        case .openai: return ["developers.openai.com", "help.openai.com", "platform.openai.com", "openai.com", "chatgpt.com"]
        case .google: return ["ai.google.dev", "gemini.google.com", "deepmind.google", "blog.google", "gemini.google", "support.google.com"]
        case .undermind: return ["undermind.ai", "www.undermind.ai"]
        }
    }

    /// Neon version of the maker's own brand colour, tuned for the dark cyberpunk surface.
    var accent: Color {
        switch self {
        case .anthropic: return Color(red: 1.00, green: 0.48, blue: 0.35)
        case .openai: return Color(red: 0.10, green: 0.95, blue: 0.69)
        case .google: return Color(red: 0.36, green: 0.65, blue: 1.00)
        case .undermind: return Color(red: 0.02, green: 0.85, blue: 0.91)
        }
    }
}

extension Target {
    var maker: Maker {
        switch fileName {
        case "openai-prompting-guide.md": return .openai
        case "google-prompting-guide.md": return .google
        case "undermind-search-guide.md": return .undermind
        default: return .anthropic
        }
    }

    /// Short label for a chip. The maker's name is already on the row, so it is not repeated.
    var chipLabel: String {
        switch id {
        case "fable": return "Fable 5.1"
        case "opus": return "Opus 5.5"
        case "sonnet": return "Sonnet 5.5"
        case "haiku": return "Haiku 4.5"
        case "luna": return "GPT-6 Luna"
        case "sol": return "GPT-6.1 Sol"
        case "astra": return "GPT-6 Astra"
        case "geminilite": return "3.5 Flash-Lite"
        case "gemini": return "3.8 Flash"
        case "geminipro": return "3.1 Pro"
        case "geminithink": return "+ Extended thinking"
        case "geminiresearch": return "+ Deep Research"
        case "undermind": return "Deep search"
        default: return label
        }
    }
}

// MARK: - Animated marks
//
// Drawn, not bundled: a single executable has no asset catalogue, and a drawn mark can move. Each
// mark is always animating (the Claude starburst breathes, the OpenAI blossom turns, the Gemini
// spark pulses, the Undermind radar sweeps). With Reduce Motion on, time is frozen at zero.

struct MakerMark: View {
    let maker: Maker
    var size: CGFloat = 30

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: Motion.reduced)) { timeline in
            let t = Motion.reduced ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, canvas in
                var ctx = context
                let c = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
                let s = min(canvas.width, canvas.height)
                switch maker {
                case .anthropic: Self.claude(&ctx, c, s, t)
                case .openai: Self.openai(&ctx, c, s, t)
                case .google: Self.gemini(&ctx, c, s, t)
                case .undermind: Self.radar(&ctx, c, s, t)
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: maker.accent.opacity(0.75), radius: 5)
        .accessibilityHidden(true)
    }

    /// Claude: a starburst of uneven rays that turn slowly and breathe out of step with each other.
    private static func claude(_ ctx: inout GraphicsContext, _ c: CGPoint, _ s: CGFloat, _ t: Double) {
        let rays = 12
        let colour = Maker.anthropic.accent
        for i in 0..<rays {
            let angle = Double(i) * (2 * .pi / Double(rays)) + t * 0.35
            let breathe = 0.5 + 0.5 * sin(t * 1.9 + Double(i) * 0.83)
            let base: Double = [0.46, 0.36, 0.42][i % 3]
            let outer = s * CGFloat(base * (0.72 + 0.28 * breathe))
            let inner = s * 0.10
            var path = Path()
            path.move(to: CGPoint(x: c.x + cos(angle) * inner, y: c.y + sin(angle) * inner))
            path.addLine(to: CGPoint(x: c.x + cos(angle) * outer, y: c.y + sin(angle) * outer))
            ctx.stroke(path, with: .color(colour.opacity(0.75 + 0.25 * breathe)),
                       style: StrokeStyle(lineWidth: s * 0.085, lineCap: .round))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.05, y: c.y - s * 0.05, width: s * 0.10, height: s * 0.10)),
                 with: .color(colour))
    }

    /// OpenAI: six interlocking loops that rotate as a blossom and pulse one after another.
    private static func openai(_ ctx: inout GraphicsContext, _ c: CGPoint, _ s: CGFloat, _ t: Double) {
        let colour = Maker.openai.accent
        for k in 0..<6 {
            var petal = ctx
            petal.translateBy(x: c.x, y: c.y)
            petal.rotate(by: .radians(Double(k) * .pi / 3 + t * 0.6))
            let pulse = 0.55 + 0.45 * sin(t * 2.2 + Double(k) * 1.05)
            let rect = CGRect(x: -s * 0.15, y: -s * 0.47, width: s * 0.30, height: s * 0.50)
            petal.stroke(Path(roundedRect: rect, cornerRadius: s * 0.15),
                         with: .color(colour.opacity(0.45 + 0.55 * pulse)),
                         style: StrokeStyle(lineWidth: s * 0.065, lineCap: .round))
        }
    }

    /// Gemini: the four-point spark with its gradient, pulsing, and two small stars that twinkle.
    private static func gemini(_ ctx: inout GraphicsContext, _ c: CGPoint, _ s: CGFloat, _ t: Double) {
        func star(_ centre: CGPoint, _ r: CGFloat) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: centre.x, y: centre.y - r))
            p.addQuadCurve(to: CGPoint(x: centre.x + r, y: centre.y), control: centre)
            p.addQuadCurve(to: CGPoint(x: centre.x, y: centre.y + r), control: centre)
            p.addQuadCurve(to: CGPoint(x: centre.x - r, y: centre.y), control: centre)
            p.addQuadCurve(to: CGPoint(x: centre.x, y: centre.y - r), control: centre)
            return p
        }
        let pulse = 0.82 + 0.18 * sin(t * 2.0)
        let gradient = Gradient(colors: [Color(red: 0.26, green: 0.52, blue: 0.96),
                                         Color(red: 0.61, green: 0.45, blue: 0.80),
                                         Color(red: 0.85, green: 0.40, blue: 0.44)])
        ctx.fill(star(c, s * 0.46 * CGFloat(pulse)),
                 with: .linearGradient(gradient, startPoint: CGPoint(x: c.x - s / 2, y: c.y - s / 2),
                                       endPoint: CGPoint(x: c.x + s / 2, y: c.y + s / 2)))
        let a = 0.3 + 0.7 * abs(sin(t * 1.4))
        let b = 0.3 + 0.7 * abs(sin(t * 1.4 + 1.3))
        ctx.fill(star(CGPoint(x: c.x + s * 0.34, y: c.y - s * 0.34), s * 0.11), with: .color(Color.white.opacity(a)))
        ctx.fill(star(CGPoint(x: c.x - s * 0.36, y: c.y + s * 0.36), s * 0.08), with: .color(Color.white.opacity(b)))
    }

    /// Undermind: a search radar. Rings, a sweeping beam with a fading trail, and blips that light
    /// up as the beam passes over them.
    private static func radar(_ ctx: inout GraphicsContext, _ c: CGPoint, _ s: CGFloat, _ t: Double) {
        let colour = Maker.undermind.accent
        for r in [0.46, 0.31, 0.16] {
            let rect = CGRect(x: c.x - s * r, y: c.y - s * r, width: s * r * 2, height: s * r * 2)
            ctx.stroke(Path(ellipseIn: rect), with: .color(colour.opacity(0.55)), lineWidth: s * 0.04)
        }
        let sweep = t * 2.4
        for i in 0..<10 {
            let angle = sweep - Double(i) * 0.09
            var path = Path()
            path.move(to: c)
            path.addLine(to: CGPoint(x: c.x + cos(angle) * s * 0.46, y: c.y + sin(angle) * s * 0.46))
            ctx.stroke(path, with: .color(colour.opacity(0.9 - Double(i) * 0.09)), lineWidth: s * 0.05)
        }
        let blips: [(Double, Double)] = [(0.9, 0.30), (2.6, 0.38), (4.4, 0.22), (5.4, 0.34)]
        for (angle, radius) in blips {
            var d = (sweep - angle).truncatingRemainder(dividingBy: 2 * .pi)
            if d < 0 { d += 2 * .pi }
            let glow = max(0.15, 1.0 - d / 2.4)
            let p = CGPoint(x: c.x + cos(angle) * s * radius, y: c.y + sin(angle) * s * radius)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - s * 0.045, y: p.y - s * 0.045, width: s * 0.09, height: s * 0.09)),
                     with: .color(Color.white.opacity(glow)))
        }
    }
}

enum Motion {
    /// Read once per launch; the marks and the scan effect freeze when the system asks for less motion.
    static let reduced: Bool = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
}
