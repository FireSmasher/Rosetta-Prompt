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

        // `--selftest --run` drives one real run through the same state object the window's buttons
        // call: keep a model against the guide, stop a run in flight, then let one run finish.
        if CommandLine.arguments.contains("--run") {
            guard let fable = targets.first(where: { $0.id == "fable" }), ClaudeRunner.findExecutable() != nil else {
                print("FAIL  run test needs the fable target and the claude CLI")
                return 1
            }
            func wait(_ seconds: Double, until done: () -> Bool) async -> Bool {
                let deadline = Date().addingTimeInterval(seconds)
                while !done() {
                    if Date() > deadline { return false }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                return true
            }
            func children() -> Int {
                let pgrep = Process()
                pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
                pgrep.arguments = ["-P", String(ProcessInfo.processInfo.processIdentifier)]
                let pipe = Pipe()
                pgrep.standardOutput = pipe
                try? pgrep.run()
                let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                pgrep.waitUntilExit()
                // pgrep lists itself as a child while it runs.
                return out.split(separator: "\n").filter { Int32($0) != pgrep.processIdentifier }.count
            }
            let state = TranslatorState()
            state.selectedTarget = fable
            state.messyPrompt = "fix the typos in this note and keep my wording: i tink the meting is on tuesday"
            state.translate()
            report(state.awaitingChoice && !state.isRunning, "first press waits on the guide",
                   state.advice.map { "\($0.verdict.badge), guide picks \($0.model.id)" } ?? "no advice")
            state.translate()
            report(state.isRunning && state.selectedTarget.id == "fable", "second press keeps Fable and starts the run")
            let launched = await wait(10) { children() > 0 }
            report(launched && state.progress?.stage == .rewriting, "rewrite call is running", "\(children()) child")
            let stopAt = Date()
            state.stop()
            let ended = await wait(6) { !state.isRunning }
            report(ended && state.notice.hasPrefix("Stopped") && state.result.isEmpty && state.errorText.isEmpty,
                   "Stop ends the run and says so", String(format: "%.2fs, notice: %@", Date().timeIntervalSince(stopAt), state.notice))
            report(children() == 0, "no model call left running after Stop", "\(children()) child")
            report(state.messyPrompt.hasPrefix("fix the typos"), "the text is still in the box after Stop")

            // A kept model is not asked about again: one press now runs to the end.
            state.translate()
            report(state.isRunning && !state.awaitingChoice, "one press runs for the kept model")
            var stages: [String] = []
            let finished = await wait(300) {
                if let now = state.progress { let name = "\(now.stage) \(now.attempt)"; if stages.last != name { stages.append(name) } }
                return !state.isRunning
            }
            report(finished && !state.result.isEmpty, "run finishes with a result", "\(state.result.count) chars; \(state.errorText)")
            report(stages.contains { $0.hasPrefix("checking") }, "tracker moved from Rewrite to Check", stages.joined(separator: ", "))
            report(state.lastRunSeconds > 0, "run time recorded", String(format: "%.0fs", state.lastRunSeconds))
            print("      " + state.checkSummary)
            print("      " + state.result.replacingOccurrences(of: "\n", with: " ").prefix(220))
            print("\n\(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")")
            return Int32(failures)
        }

        print("Rosetta Prompt self test, \(live ? "live" : "offline"), \(targets.count) targets")
        report(FileManager.default.fileExists(atPath: referenceDir), "reference folder", referenceDir)
        report(FileManager.default.fileExists(atPath: checkerPath), "checker script")
        let claude = ClaudeRunner.findExecutable()
        report(claude != nil, "claude CLI found", claude ?? "not found, rewrites cannot run")

        report(TranslatorState().selectedTarget.id == "opus", "default target is Opus 5.5", TranslatorState().selectedTarget.id)

        // Keeping a pick: the guide interrupts once for a model mismatch, a second press of
        // Translate keeps the model, and a kept model is not asked about again until it changes.
        if let fable = targets.first(where: { $0.id == "fable" }) {
            let state = TranslatorState()
            let small = "fix this typo"
            state.selectedTarget = fable
            state.messyPrompt = small
            state.translate()
            report(state.awaitingChoice && !state.isRunning, "guide waits on a model mismatch",
                   state.advice.map { "\($0.verdict.badge), guide picks \($0.model.id)" } ?? "no advice")
            state.keepSelected()
            let advice = Advisor.assess(task: small, context: "", selected: fable)
            report(state.selectedTarget.id == "fable" && !state.awaitingChoice && advice.map { !state.needsChoice($0) } == true,
                   "a kept model stays selected and is not asked about again")
            state.selectedTarget = targets[1]
            state.selectedTarget = fable
            report(advice.map { state.needsChoice($0) } == true, "picking another model clears the keep")
        } else { report(false, "fable target exists") }

        // Stop: cancelling the task ends the child process and surfaces as a cancellation.
        let sleeper = Task { try await runProcess(exe: "/bin/sleep", arguments: ["30"]) }
        try? await Task.sleep(nanoseconds: 300_000_000)
        let stopAt = Date()
        sleeper.cancel()
        var stopped = false
        do { _ = try await sleeper.value } catch is CancellationError { stopped = true } catch {}
        let stopTook = Date().timeIntervalSince(stopAt)
        report(stopped && stopTook < 3, "a stopped run ends its child process", String(format: "%.2fs", stopTook))

        // Tracker line: the try count appears from the second try, then the clock, then the yardstick.
        let line = RunTracker.detail(RunProgress(stage: .rewriting, attempt: 2, maxAttempts: 3),
                                     elapsed: 65, last: 48, stopping: false)
        report(line == "try 2 of 3 · 1:05 · last run 0:48", "run tracker line", line)

        // Effort belongs to the model the prompt is written for. The same task is scored once, then
        // each model reads its own row: a class 3 task is medium on Opus 5.5 and high on Fable 5.1.
        // The scorer script must agree with the app on every fixture, curly quotes included.
        let fixtures = [
            "fix this typo",
            "Summarise this article in three bullet points for a friend who has not read it yet and does not know the topic at all, keep it short and plain and skip the jargon, thanks a lot for the help with this one today",
            "Compare three database designs for a booking app, recommend one, and explain the tradeoffs between cost, speed and how hard each is to change later. Then outline the migration in order, with what could go wrong at each step and how to roll back.",
            "Review the \u{201C}contract\u{201D} please",
            "Review the \"contract\" please",
        ]
        if let fable = targets.first(where: { $0.id == "fable" }), let opus = targets.first(where: { $0.id == "opus" }) {
            if let hard = Advisor.assess(task: fixtures[2], context: "", selected: fable) {
                let onFable = Advisor.effort(for: fable, advice: hard), onOpus = Advisor.effort(for: opus, advice: hard)
                report(hard.neededClass == 3 && onOpus == Rubric.value("effort-by-model", "opus.3", fallback: "medium")
                       && onFable == Rubric.value("effort-by-model", "fable.3", fallback: Rubric.value("effort", "3", fallback: "high")),
                       "a kept model gets its own effort, not the guide's", "class \(hard.neededClass): opus \(onOpus), fable \(onFable)")
            } else { report(false, "class 3 fixture is scored") }
            if let risky = Advisor.assess(task: fixtures[3], context: "", selected: fable) {
                report(risky.highStakes && Advisor.effort(for: fable, advice: risky) == "high", "stakes floor holds for a kept model",
                       Advisor.effort(for: fable, advice: risky))
            } else { report(false, "stakes fixture is scored") }

            let scorer = (skillDir as NSString).appendingPathComponent("scripts/score_prompt.py")
            for (index, task) in fixtures.enumerated() {
                guard let swift = Advisor.assess(task: task, context: "", selected: fable) else {
                    report(false, "fixture \(index + 1) is scored"); continue
                }
                let ran = try? await runProcess(exe: "/usr/bin/python3", arguments: [scorer, "--text", task, "--target", "fable"])
                let json = ran.flatMap { $0.out.data(using: .utf8) }.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
                let theirs = "\(json?["model"] as? String ?? "?") \(json?["effort"] as? String ?? "none") class \(json?["class"] as? Int ?? 0) fable \(json?["target_effort"] as? String ?? "?")"
                let ours = "\(swift.model.id) \(swift.model.id == "haiku" ? "none" : swift.effort) class \(swift.neededClass) fable \(Advisor.effort(for: fable, advice: swift))"
                report(ours == theirs, "app and scorer script agree on fixture \(index + 1)", ours == theirs ? ours : "app: \(ours); script: \(theirs)")
            }
        }

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
                let suggested = target.id == "haiku" ? nil : advice.map { Advisor.effort(for: target, advice: $0) }
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
