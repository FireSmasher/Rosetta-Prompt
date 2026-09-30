import Foundation

// MARK: - Self test
//
//   RosettaPrompt --selftest           offline: references, requests, scoring, links, checker rules
//   RosettaPrompt --selftest --live    also runs one real rewrite and check per target
//
// Exit status is the number of failures, so it can gate a release. The live pass spends credits: one
// rewrite and one judge call per target.

@MainActor
enum SelfTest {
    private static let generalTask = "so i need a short email to my landlord asking him to fix the heating, it has been broken 3 days, polite but firm"
    private static let searchTask = "find papers on whether spaced repetition helps medical students remember anatomy"
    private static let cleanRewrite = "Write a short, polite but firm email to my landlord asking him to repair the heating, which has been broken for three days. Say what I need and by when, and ask him to reply with a date."
    private static let badRewrite = "Here is the rewritten prompt:\n\nWrite an email to the landlord about the heating. [TBD]"

    private static func task(for target: Target) -> String {
        target.id == "undermind" ? searchTask : generalTask
    }

    static func run(live: Bool) async -> Int32 {
        var failures = 0
        func report(_ ok: Bool, _ label: String, _ detail: String = "") {
            print("\(ok ? "PASS" : "FAIL")  \(label)\(detail.isEmpty ? "" : "  " + detail)")
            if !ok { failures += 1 }
        }

        print("Rosetta Prompt self test, \(live ? "live" : "offline"), \(targets.count) targets")
        report(FileManager.default.fileExists(atPath: referenceDir), "reference folder", referenceDir)
        report(FileManager.default.fileExists(atPath: checkerPath), "checker script")
        let claude = ClaudeRunner.findExecutable()
        report(claude != nil, "claude CLI found", claude ?? "not found, rewrites cannot run")

        report(TranslatorState().selectedTarget.id == "opus", "default target is Opus 5.5", TranslatorState().selectedTarget.id)

        // Makers: every company has targets, and its workspace is on its own domains.
        for maker in Maker.allCases {
            let own = targets.filter { $0.maker == maker }
            report(!own.isEmpty, "\(maker.name) has targets", own.map(\.id).joined(separator: ", "))
            let host = maker.workspace.host ?? ""
            report(maker.hosts.contains(host), "\(maker.name) workspace is on its own site", host)
            let home = maker.homepage.host ?? ""
            report(maker.hosts.contains(home) || maker == .google, "\(maker.name) homepage is on its own site", home)
        }

        // Gemini functions combine with a model: one request carries the model's notes and both functions'.
        if let flash = targets.first(where: { $0.id == "geminipro" }) {
            let fns = targets.filter(\.isFunction)
            let combined = (try? buildRequest(target: flash, messyPrompt: generalTask, extraContext: "",
                                              suggestedEffort: nil, functions: fns)) ?? ""
            report(combined.contains("Gemini 3.1 Pro notes") || combined.contains("preview model"), "combined request has the model notes")
            report(combined.contains("autonomously plans"), "combined request has the Deep Research notes")
            report(combined.contains("thinking_level"), "combined request has the extended thinking notes")
        }

        for target in targets {
            print("\n== \(target.label)  [\(target.maker.name), \(target.scored ? "scored" : "product")]")

            // 1. The three reference sections the rewrite is built from must exist and have body text.
            for (name, header) in [("general", target.generalHeader), ("specific", target.specificHeader)] {
                do {
                    let body = try loadSection(fileName: target.fileName, header: header)
                    report(body.count > 200, "\(name) section loads", "\(body.count) chars")
                } catch {
                    report(false, "\(name) section loads", error.localizedDescription)
                }
            }
            let avoid = (try? loadSection(fileName: target.fileName, header: target.avoidHeader)) ?? ""
            report(!avoid.isEmpty, "over-apply section loads", "\(avoid.count) chars")

            // 2. The request builds and names the target.
            do {
                let request = try buildRequest(target: target, messyPrompt: task(for: target), extraContext: "",
                                               suggestedEffort: nil)
                report(request.contains("<target_model>\(target.label)</target_model>"), "request names the target")
                report(!request.contains("\\("), "request has no unfilled placeholder")
            } catch {
                report(false, "request builds", error.localizedDescription)
            }

            // 3. Sources: every link is on the maker's own domains and is well formed.
            var bad: [String] = []
            for link in target.sourceLinks {
                let host = URL(string: link.url)?.host ?? ""
                if !target.maker.hosts.contains(host) { bad.append(host.isEmpty ? link.url : host) }
            }
            report(bad.isEmpty && !target.sourceLinks.isEmpty, "all \(target.sourceLinks.count) source links are the maker's own",
                   bad.joined(separator: ", "))
            report(target.confidencePercent > 0 && target.confidencePercent <= 100 && !target.confidenceCriteria.isEmpty,
                   "confidence is stated with criteria", "\(target.confidencePercent)%")

            // 3b. Effort lab: a job, the maker's quote and a link on its own domain for every level it has.
            let levels = Lab.levels(for: target.id)
            report(!levels.isEmpty, "effort lab lists levels", levels.joined(separator: ", "))
            var labBad: [String] = []
            for level in levels {
                guard let entry = Lab.entry(target.id, level) else { labBad.append("\(level): no row"); continue }
                for link in [entry.quoteURL, entry.breaks == nil ? "" : entry.breakURL] where !link.isEmpty {
                    if !target.maker.hosts.contains(URL(string: link)?.host ?? "") { labBad.append("\(level): \(link)") }
                }
                if entry.quote.isEmpty || entry.job.isEmpty { labBad.append("\(level): empty") }
                if Rubric.value("style", "no_long_dash", fallback: "off") == "on",
                   [entry.job, entry.worth, entry.quote, entry.breaks ?? ""].contains(where: { $0.contains("\u{2014}") || $0.contains("\u{2013}") }) {
                    labBad.append("\(level): long dash")
                }
            }
            report(labBad.isEmpty, "effort lab rows complete and sourced on the maker's own site", labBad.joined(separator: "; "))

            // 4. Model pick: scored targets get advice that points at a real target, products get none.
            let advice = Advisor.assess(task: task(for: target), context: "", selected: target)
            if target.scored {
                if let advice {
                    report(targets.contains { $0.id == advice.model.id }, "advisor recommends a real target",
                           "\(advice.model.id) at \(advice.effort), \(advice.verdict.badge)")
                    report(!advice.positioning.isEmpty, "advisor has a positioning line", advice.model.id)
                    report(!Lab.lines(for: advice.model.id).isEmpty, "ladder has example jobs", advice.model.id)
                } else {
                    report(false, "advisor returns advice for a scored target")
                }
            } else {
                report(advice == nil, "product target is not scored")
            }

            // 5. The checker accepts this target, approves a clean rewrite, and rejects a bad one.
            let good = await EvalRunner.check(target: target, original: task(for: target), rewrite: cleanRewrite,
                                              context: "", attempt: 1, noJudge: true)
            report(good.result?.approved == true, "checker approves a clean rewrite", good.problem)
            let broken = await EvalRunner.check(target: target, original: task(for: target), rewrite: badRewrite,
                                                context: "", attempt: 1, noJudge: true)
            report(broken.result?.approved == false, "checker rejects a bad rewrite",
                   broken.result?.blocking.map(\.rule).joined(separator: ", ") ?? broken.problem)

            // 6. Live: one real rewrite through the same pipeline the window uses.
            if live {
                guard claude != nil else { report(false, "live rewrite", "no claude CLI"); continue }
                let suggested = target.id == "haiku" ? nil : advice?.effort
                let effort = target.scored ? Advisor.engineEffort(for: advice) : "medium"
                do {
                    let outcome = try await RewritePipeline.run(target: target, messy: task(for: target), context: "",
                                                                suggested: suggested, effort: effort)
                    let text = outcome.output
                    report(text.count > 40, "live rewrite returns text", "\(text.count) chars, \(outcome.attempts) attempt(s)")
                    report(!text.hasPrefix("```"), "live rewrite is not fenced")
                    report(outcome.check.result != nil, "live checks ran", outcome.check.problem)
                    let approved = outcome.check.result?.approved ?? false
                    report(approved, "live rewrite passes its checks",
                           outcome.check.result?.blocking.map(\.rule).joined(separator: ", ") ?? "")
                    print("      " + text.replacingOccurrences(of: "\n", with: " ").prefix(200))
                } catch {
                    report(false, "live rewrite", error.localizedDescription)
                }
            }
        }

        // Effort lab figures: the measured cost and the race both carry a source on Anthropic's own site.
        let anthropicHosts = Maker.anthropic.hosts
        if let cost = Lab.costSource() {
            report(anthropicHosts.contains(URL(string: cost.url)?.host ?? ""), "lab cost figures are sourced on anthropic's site", cost.label)
        } else { report(false, "lab cost figures have a source") }
        if let race = Lab.race() {
            report(anthropicHosts.contains(URL(string: race.url)?.host ?? "") && race.accuracy.1 > race.accuracy.0,
                   "lab race figures are sourced and ordered", "\(race.accuracy.0) against \(race.accuracy.1)")
        } else { report(false, "lab race figures exist") }
        report(Lab.clock(index: 0, count: 6) == "06:40" && Lab.clock(index: 4, count: 5) == "03:10", "lab clock maps levels to hours")
        report(Lab.inputPrice("opus") == 4 && Lab.inputPrice("luna") == 0.10, "lab reads list prices", "opus and luna")

        // Ladders: every rung on both ladders resolves to a target.
        for family in ["anthropic", "openai"] {
            let rungs = Ladder.rungs(for: family)
            let missing = rungs.filter { $0.target == nil }.map(\.id)
            report(missing.isEmpty && !rungs.isEmpty, "\(family) ladder rungs are all targets", missing.joined(separator: ", "))
        }

        print("\n\(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")")
        return Int32(failures)
    }
}
