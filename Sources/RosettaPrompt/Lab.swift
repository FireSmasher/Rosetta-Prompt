import SwiftUI
import AppKit

// MARK: - Effort lab
//
// One sheet that answers "what can this model really do at this effort level". It reads the `lab`
// tables in model-selection.md (and the local file, which replaces `lab` with your own jobs), so the
// job is yours while the quote, the caveat and the cost figures are always the maker's own words,
// each with its link. Three views of the same facts:
//   Day:  scrub through a day, one effort level per hour, and watch the job, its source and the
//         thing that goes wrong there change.
//   Cost: a meter of what one level costs against another, drawn only from figures the maker
//         published. Where no figure exists the card says so instead of inventing one.
//   Race: Haiku 4.5 against Opus 5.5 on Anthropic's own measured quiz.

struct LabEntry {
    let job: String
    let worth: String
    let quote: String
    let quoteLabel: String
    let quoteURL: String
    let breaks: String?
    let breakLabel: String
    let breakURL: String
}

@MainActor
enum Lab {
    private static let separator = " ;; "

    private static func parts(_ row: String) -> [String] {
        row.components(separatedBy: separator).map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// The effort levels a target really has, in order. One entry for a target with no effort setting.
    static func levels(for id: String) -> [String] {
        Rubric.list("lab-levels", id, fallback: [])
    }

    static func label(_ level: String) -> String {
        Rubric.value("lab-level-label", level, fallback: level)
    }

    static func entry(_ id: String, _ level: String) -> LabEntry? {
        let key = "\(id).\(level)"
        let jobRow = parts(Rubric.value("lab", key, fallback: ""))
        let factRow = parts(Rubric.value("lab-fact", key, fallback: ""))
        guard jobRow.count >= 1, !jobRow[0].isEmpty, factRow.count >= 3 else { return nil }
        let breakRow = parts(Rubric.value("lab-break", key, fallback: ""))
        return LabEntry(job: jobRow[0],
                        worth: jobRow.count > 1 ? jobRow[1] : "",
                        quote: factRow[0], quoteLabel: factRow[1], quoteURL: factRow[2],
                        breaks: breakRow.count >= 3 ? breakRow[0] : nil,
                        breakLabel: breakRow.count >= 3 ? breakRow[1] : "",
                        breakURL: breakRow.count >= 3 ? breakRow[2] : "")
    }

    /// One line per level, for the compact hover block in the guide panel.
    static func lines(for id: String) -> [(level: String, job: String)] {
        levels(for: id).compactMap { level in
            entry(id, level).map { (level: label(level), job: $0.job) }
        }
    }

    /// Hours of a day, one per level: half awake at 06:40, the question that keeps you up at 03:10.
    private static let day = ["06:40", "08:15", "11:30", "15:45", "23:30", "03:10"]

    static func clock(index: Int, count: Int) -> String {
        switch count {
        case 6: return day[min(index, 5)]
        case 5: return day[min(index + 1, 5)]
        case 3: return [day[1], day[3], day[5]][min(index, 2)]
        case 2: return [day[2], day[5]][min(index, 1)]
        default: return "any hour"
        }
    }

    /// Anthropic's measured cost of Opus 5.5 at one level against high, which is 100.
    static func cost(_ id: String, _ level: String) -> (percent: Int, note: String)? {
        let row = parts(Rubric.value("lab-cost", "\(id).\(level)", fallback: ""))
        guard row.count >= 2, let p = Int(row[0]) else { return nil }
        return (p, row[1])
    }

    static func costSource() -> (quote: String, label: String, url: String)? {
        let row = parts(Rubric.value("lab-cost", "source", fallback: ""))
        return row.count >= 3 ? (row[0], row[1], row[2]) : nil
    }

    static func race() -> (accuracy: (Int, Int), cost: (Int, Int), quote: String, label: String, url: String)? {
        func pair(_ key: String) -> (Int, Int)? {
            let row = parts(Rubric.value("lab-race", key, fallback: ""))
            guard row.count >= 2, let a = Int(row[0]), let b = Int(row[1]) else { return nil }
            return (a, b)
        }
        let src = parts(Rubric.value("lab-race", "source", fallback: ""))
        guard let acc = pair("accuracy"), let cst = pair("cost"), src.count >= 3 else { return nil }
        return (acc, cst, src[0], src[1], src[2])
    }

    /// The first dollar figure of a price row such as "$4 / $20 per M".
    static func inputPrice(_ id: String) -> Double? {
        let text = Rubric.value("price", id, fallback: "")
        guard let dollar = text.firstIndex(of: "$") else { return nil }
        let digits = text[text.index(after: dollar)...].prefix { $0.isNumber || $0 == "." }
        return Double(digits)
    }
}

// MARK: - The sheet

struct LabSheet: View {
    @ObservedObject var state: TranslatorState

    private var target: Target { targets.first { $0.id == state.labTargetID } ?? state.selectedTarget }
    private var accent: Color { target.maker.accent }
    private var levels: [String] { Lab.levels(for: target.id) }
    private var index: Int { min(max(Int(state.labIndex.rounded()), 0), max(levels.count - 1, 0)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Picker("View", selection: Binding(get: { state.labMode },
                                              set: { state.labMode = $0; if $0 == 2 { state.kickRace() } })) {
                Text("Day").tag(0)
                Text("Cost").tag(1)
                Text("Race").tag(2)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityLabel("Effort lab view")

            if state.labMode == 2 {
                RaceView(shown: state.labRaceShown)
            } else {
                targetRow
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if state.labMode == 0 { dayView } else { CostView(target: target, levels: levels, index: index) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(18)
        .frame(minWidth: 680, minHeight: 600)
        .background(Cyber.bg)
        .onAppear { if state.labMode == 2 { state.kickRace() } }
    }

    private var header: some View {
        HStack(spacing: 10) {
            MakerMark(maker: target.maker, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("EFFORT LAB").font(.title3.weight(.heavy)).tracking(2).foregroundStyle(Cyber.text)
                Text("What each model and each effort level can really do, in jobs from your own week, with the maker's own words beside each one.")
                    .font(.caption).foregroundStyle(Cyber.mute)
            }
            Spacer()
            Button("Done") { state.labOpen = false }
                .buttonStyle(CyberButtonStyle(tint: Cyber.pink))
                .keyboardShortcut(.cancelAction)
        }
    }

    // MARK: Target chips

    private var targetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(targets) { t in
                    Button {
                        state.labTargetID = t.id
                        state.labIndex = 0
                    } label: {
                        Text(t.chipLabel)
                            .font(.caption.weight(t.id == target.id ? .bold : .regular))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .foregroundStyle(t.id == target.id ? Cyber.bg : Cyber.text)
                            .background(RoundedRectangle(cornerRadius: 5)
                                .fill(t.id == target.id ? t.maker.accent : t.maker.accent.opacity(0.14)))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(t.maker.accent.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t.label)
                    .accessibilityAddTraits(t.id == target.id ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: Day view

    @ViewBuilder
    private var dayView: some View {
        if levels.isEmpty {
            Text("No examples for \(target.label).").font(.callout).foregroundStyle(Cyber.mute)
        } else {
            scrubber
            if let entry = Lab.entry(target.id, levels[index]) {
                card(title: "THE JOB", tint: accent) {
                    Text(entry.job).font(.title3.weight(.semibold)).foregroundStyle(Cyber.text)
                    if !entry.worth.isEmpty {
                        Text("Worth it: \(entry.worth)").font(.callout).foregroundStyle(Cyber.mute)
                    }
                }
                card(title: "THE MAKER SAYS", tint: Cyber.cyan) {
                    Text("\u{201C}\(entry.quote)\u{201D}").font(.callout).foregroundStyle(Cyber.text)
                    sourceLink(entry.quoteLabel, entry.quoteURL)
                }
                card(title: "WHAT WOULD BREAK", tint: Cyber.yellow) {
                    if let text = entry.breaks {
                        Text("\u{201C}\(text)\u{201D}").font(.callout).foregroundStyle(Cyber.text)
                        sourceLink(entry.breakLabel, entry.breakURL)
                    } else {
                        Text("\(target.maker.name) publishes no caveat for this level, so none is shown. A card that invented one would be worse than an empty one.")
                            .font(.callout).foregroundStyle(Cyber.mute)
                    }
                }
            }
        }
    }

    private var scrubber: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Lab.clock(index: index, count: levels.count))
                    .font(.largeTitle.monospacedDigit().weight(.bold))
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.8), radius: 6)
                Text(levels.count == 1 ? "\(target.label): \(Lab.label(levels[0]))" : "\(target.label) at \(Lab.label(levels[index]))")
                    .font(.headline).foregroundStyle(Cyber.text)
                Spacer()
                Text(target.maker.name).font(.caption).foregroundStyle(Cyber.mute)
            }
            if levels.count > 1 {
                Slider(value: $state.labIndex, in: 0...Double(levels.count - 1), step: 1)
                    .tint(accent)
                    .accessibilityLabel("Effort level")
                    .accessibilityValue(Lab.label(levels[index]))
                HStack(spacing: 0) {
                    ForEach(Array(levels.enumerated()), id: \.offset) { i, level in
                        Button { withAnimation(Motion.reduced ? nil : .easeOut(duration: 0.2)) { state.labIndex = Double(i) } } label: {
                            Text(Lab.label(level))
                                .font(i == index ? Font.caption.weight(.bold) : Font.caption)
                                .foregroundStyle(i == index ? accent : Cyber.mute)
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text(target.scored
                     ? "This model has no effort setting, so there is one card."
                     : "\(target.chipLabel) has no effort setting of its own, so there is one card for what it does.")
                    .font(.caption).foregroundStyle(Cyber.mute)
            }
        }
    }

    private func card<Content: View>(title: String, tint: Color, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption2.weight(.heavy)).tracking(1.6).foregroundStyle(tint)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Cyber.panel)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(0.5), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func sourceLink(_ label: String, _ url: String) -> some View {
        Group {
            if let link = URL(string: url) {
                Link(destination: link) { Text(label).underline() }
            } else {
                Text(label)
            }
        }
        .font(.caption)
        .foregroundStyle(accent)
    }
}

// MARK: - Cost view

/// A bar per level where the maker measured one, or a bar per model at list price where it did not.
struct CostView: View {
    let target: Target
    let levels: [String]
    let index: Int

    private var accent: Color { target.maker.accent }
    private var measured: Bool { levels.contains { Lab.cost(target.id, $0) != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if measured, let source = Lab.costSource() {
                panel(title: "WHAT EACH LEVEL COSTS ON \(target.chipLabel.uppercased()), HIGH IS 100") {
                    ForEach(Array(levels.enumerated()), id: \.offset) { i, level in
                        if let cost = Lab.cost(target.id, level) {
                            bar(label: Lab.label(level), value: Double(cost.percent), maxValue: 250,
                                text: "\(cost.percent)", note: cost.note, highlight: i == index)
                        } else {
                            Text("\(Lab.label(level)): Anthropic published no cost figure for this level.")
                                .font(.caption).foregroundStyle(Cyber.mute)
                        }
                    }
                    Text("\u{201C}\(source.quote)\u{201D}").font(.caption).foregroundStyle(Cyber.text)
                    link(source.label, source.url)
                }
            } else {
                Text("\(target.maker.name) published no cost per effort level for \(target.chipLabel), so there is no level meter here. Below is list price per million input tokens, which is what a model costs before effort changes how many tokens a job uses.")
                    .font(.callout).foregroundStyle(Cyber.mute)
            }
            priceMeter
        }
    }

    private var priceMeter: some View {
        let family = target.maker == .openai ? "openai" : "anthropic"
        let rungs = (target.maker == .anthropic || target.maker == .openai) ? Ladder.rungs(for: family) : []
        let priced = rungs.compactMap { rung -> (Rung, Double)? in
            Lab.inputPrice(rung.id).map { (rung, $0) }
        }
        let top = priced.map(\.1).max() ?? 1
        return panel(title: "LIST PRICE, INPUT, PER MILLION TOKENS") {
            if priced.isEmpty {
                Text("\(target.chipLabel) is a product, not a priced model, so there is no per token price to compare.")
                    .font(.caption).foregroundStyle(Cyber.mute)
            } else {
                ForEach(Array(priced.enumerated()), id: \.offset) { _, item in
                    bar(label: item.0.label, value: item.1, maxValue: top,
                        text: "$\(item.1 < 1 ? String(format: "%.2f", item.1) : String(format: "%g", item.1))",
                        note: "", highlight: item.0.id == target.id)
                }
            }
        }
    }

    private func panel<Content: View>(title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption2.weight(.heavy)).tracking(1.4).foregroundStyle(Cyber.yellow)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Cyber.panel)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Cyber.yellow.opacity(0.45), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func bar(label: String, value: Double, maxValue: Double, text: String, note: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(label).font(.caption.weight(highlight ? .bold : .regular))
                    .foregroundStyle(highlight ? accent : Cyber.text)
                    .frame(width: 92, alignment: .leading)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(accent.opacity(0.10))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(accent.opacity(highlight ? 1 : 0.5))
                            .frame(width: max(4, geo.size.width * CGFloat(value / maxValue)))
                            .shadow(color: accent.opacity(highlight ? 0.8 : 0), radius: 5)
                    }
                }
                .frame(height: 14)
                Text(text).font(.caption.monospacedDigit().weight(.bold)).foregroundStyle(Cyber.text)
                    .frame(width: 52, alignment: .trailing)
            }
            if !note.isEmpty {
                Text(note).font(.caption2).foregroundStyle(Cyber.mute).padding(.leading, 100)
            }
        }
    }

    private func link(_ label: String, _ url: String) -> some View {
        Group {
            if let u = URL(string: url) { Link(destination: u) { Text(label).underline() } } else { Text(label) }
        }
        .font(.caption).foregroundStyle(accent)
    }
}

// MARK: - Race view

/// Haiku 4.5 against Opus 5.5 on the one head to head Anthropic measured. The bars fill in when the
/// view appears. The figures are a science quiz, not your jobs, and the card says so.
struct RaceView: View {
    let shown: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let race = Lab.race() {
                    HStack(alignment: .top, spacing: 12) {
                        racer(name: "Haiku 4.5", id: "haiku", level: "none", accuracy: race.accuracy.0, cost: race.cost.0,
                              maker: Maker.anthropic, tint: Cyber.cyan)
                        racer(name: "Opus 5.5", id: "opus", level: "medium", accuracy: race.accuracy.1, cost: race.cost.1,
                              maker: Maker.anthropic, tint: Cyber.pink)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("THE MAKER SAYS").font(.caption2.weight(.heavy)).tracking(1.6).foregroundStyle(Cyber.cyan)
                        Text("\u{201C}\(race.quote)\u{201D}").font(.callout).foregroundStyle(Cyber.text)
                        if let link = URL(string: race.url) {
                            Link(destination: link) { Text(race.label).underline() }
                                .font(.caption).foregroundStyle(Maker.anthropic.accent)
                        }
                        Text("Anthropic measured this on GPQA Diamond science questions, not on your jobs. Accuracy is the share answered correctly. Cost is per question, Opus 5.5 at 100.")
                            .font(.caption).foregroundStyle(Cyber.mute)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Cyber.panel)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Cyber.cyan.opacity(0.5), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private func racer(name: String, id: String, level: String, accuracy: Int, cost: Int, maker: Maker, tint: Color) -> some View {
        let entry = Lab.entry(id, level)
        return VStack(alignment: .leading, spacing: 8) {
            Text(name.uppercased()).font(.headline.weight(.heavy)).tracking(2).foregroundStyle(tint)
            meter("Accuracy", value: accuracy, suffix: "%", tint: tint)
            meter("Cost", value: cost, suffix: "", tint: tint)
            if let entry {
                Divider().overlay(tint.opacity(0.4))
                Text("Your job at \(name)").font(.caption2.weight(.heavy)).foregroundStyle(Cyber.mute)
                Text(entry.job).font(.callout.weight(.semibold)).foregroundStyle(Cyber.text)
                if !entry.worth.isEmpty { Text("Worth it: \(entry.worth)").font(.caption).foregroundStyle(Cyber.mute) }
                if let breaks = entry.breaks {
                    Text("What would break").font(.caption2.weight(.heavy)).foregroundStyle(Cyber.yellow)
                    Text("\u{201C}\(breaks)\u{201D}").font(.caption).foregroundStyle(Cyber.text)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Cyber.panel)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(0.55), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func meter(_ label: String, value: Int, suffix: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.caption).foregroundStyle(Cyber.mute)
                Spacer()
                Text("\(value)\(suffix)").font(.callout.monospacedDigit().weight(.bold)).foregroundStyle(Cyber.text)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(tint.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3).fill(tint)
                        .frame(width: shown ? max(4, geo.size.width * CGFloat(value) / 100) : 4)
                        .shadow(color: tint.opacity(0.8), radius: 5)
                        .animation(Motion.reduced ? nil : .easeOut(duration: 0.9), value: shown)
                }
            }
            .frame(height: 14)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)\(suffix)")
    }
}
