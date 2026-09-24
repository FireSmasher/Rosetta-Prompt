import SwiftUI
import AppKit

// MARK: - Reference loading

/// One checkable fact behind a confidence percentage, e.g. "official prompting page exists". Shown
/// as a ticked or unticked line in the UI so the percent isn't the only signal of source rigor.
struct ConfidenceCriterion: Hashable {
    let label: String
    let met: Bool
}

/// A page that actually contributed to a target's entry, shown as a short clickable link in place
/// of the old blanket "Primary Anthropic docs" line.
struct SourceLink: Hashable {
    let label: String
    let url: String
}

struct Target: Identifiable, Hashable {
    let id: String
    let label: String
    let fileName: String
    let generalHeader: String
    let specificHeader: String
    /// Both guides carry a section on what not to over-apply. The skill's build step asks for it by
    /// name and the app was referring to it without ever supplying it, so it is loaded now.
    let avoidHeader: String = "## What NOT to over-apply"
    // When the underlying prompting guidance was actually researched, not today's date and not a
    // build date. Shown in the app so a stale reference is visible at a glance rather than trusted
    // forever. confidencePercent and confidenceNote are my own judgment call about source rigor
    // (primary official docs versus secondary commentary), not a number either provider publishes.
    let sourceDate: String
    let confidencePercent: Int
    let confidenceNote: String
    /// The criteria the percent is actually built from. Ticked/unticked, not just asserted.
    let confidenceCriteria: [ConfidenceCriterion]
    /// Only the pages that fed this target's entry, not every page either reference guide cites.
    let sourceLinks: [SourceLink]
}

let targets: [Target] = [
    Target(id: "fable", label: "Claude Fable 5.1",
           fileName: "anthropic-prompting-guide.md",
           generalHeader: "## General principles (all current Claude models)",
           specificHeader: "## Fable 5.1-specific notes",
           sourceDate: "16 Sep 2026",
           confidencePercent: 95,
           confidenceNote: "Primary Anthropic docs.",
           confidenceCriteria: [
               .init(label: "Official prompting page exists", met: true),
               .init(label: "Model overview page read", met: true),
               .init(label: "What's new page read", met: true),
               .init(label: "Migration guide covered", met: true),
           ],
           sourceLinks: [
               .init(label: "prompt-engineering/claude-prompting-best-practices", url: "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices"),
               .init(label: "prompt-engineering/prompting-claude-fable-5-1", url: "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1"),
               .init(label: "models/fable-5-1/overview", url: "https://platform.claude.com/docs/en/models/fable-5-1/overview"),
               .init(label: "models/fable-5-1/migration-guide", url: "https://platform.claude.com/docs/en/models/fable-5-1/migration-guide"),
               .init(label: "models/overview", url: "https://platform.claude.com/docs/en/models/overview"),
               .init(label: "about-claude/models/optimizing-for-cost-and-intelligence", url: "https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence"),
           ]),
    Target(id: "opus", label: "Claude Opus 5.5",
           fileName: "anthropic-prompting-guide.md",
           generalHeader: "## General principles (all current Claude models)",
           specificHeader: "## Opus 5.5-specific notes",
           sourceDate: "24 Sep 2026",
           confidencePercent: 95,
           confidenceNote: "Primary Anthropic docs.",
           confidenceCriteria: [
               .init(label: "Official prompting page exists", met: true),
               .init(label: "Model overview page read", met: true),
               .init(label: "What's new page read", met: true),
               .init(label: "Migration guide covered", met: true),
           ],
           sourceLinks: [
               .init(label: "prompt-engineering/claude-prompting-best-practices", url: "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices"),
               .init(label: "prompt-engineering/prompting-claude-opus-5-5", url: "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5"),
               .init(label: "models/opus-5-5/overview", url: "https://platform.claude.com/docs/en/models/opus-5-5/overview"),
               .init(label: "models/opus-5-5/whats-new-opus-5-5", url: "https://platform.claude.com/docs/en/models/opus-5-5/whats-new-opus-5-5"),
               .init(label: "models/opus-5-5/migration-guide", url: "https://platform.claude.com/docs/en/models/opus-5-5/migration-guide"),
               .init(label: "models/overview", url: "https://platform.claude.com/docs/en/models/overview"),
           ]),
    Target(id: "sonnet", label: "Claude Sonnet 5",
           fileName: "anthropic-prompting-guide.md",
           generalHeader: "## General principles (all current Claude models)",
           specificHeader: "## Sonnet 5-specific notes",
           sourceDate: "16 Sep 2026",
           confidencePercent: 95,
           confidenceNote: "Primary Anthropic docs.",
           confidenceCriteria: [
               .init(label: "Official prompting page exists", met: true),
               .init(label: "Model overview page read", met: true),
               .init(label: "What's new page read", met: true),
               .init(label: "Migration guide covered", met: true),
           ],
           sourceLinks: [
               .init(label: "prompt-engineering/claude-prompting-best-practices", url: "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices"),
               .init(label: "prompt-engineering/prompting-claude-sonnet-5", url: "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5"),
               .init(label: "models/sonnet-5/overview", url: "https://platform.claude.com/docs/en/models/sonnet-5/overview"),
               .init(label: "models/sonnet-5/whats-new-sonnet-5", url: "https://platform.claude.com/docs/en/models/sonnet-5/whats-new-sonnet-5"),
               .init(label: "models/sonnet-5/migration-guide", url: "https://platform.claude.com/docs/en/models/sonnet-5/migration-guide"),
               .init(label: "models/overview", url: "https://platform.claude.com/docs/en/models/overview"),
           ]),
    // Appended after Sonnet rather than placed first, so targets[1] (Opus, the default) and
    // targets[2] (Sonnet, the Advisor fallback) keep their indices.
    Target(id: "haiku", label: "Claude Haiku 4.5",
           fileName: "anthropic-prompting-guide.md",
           generalHeader: "## General principles (all current Claude models)",
           specificHeader: "## Haiku 4.5-specific notes",
           sourceDate: "16 Sep 2026 (general pages only)",
           confidencePercent: 80,
           confidenceNote: "Primary Anthropic docs, but Anthropic publishes no Haiku 4.5 prompting page, so general guidance only.",
           confidenceCriteria: [
               .init(label: "Official prompting page exists", met: false),
               .init(label: "Model overview page read", met: true),
               .init(label: "What's new page read", met: false),
               .init(label: "Migration guide covered", met: true),
           ],
           sourceLinks: [
               .init(label: "prompt-engineering/claude-prompting-best-practices", url: "https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices"),
               .init(label: "models/haiku-4-5/overview", url: "https://platform.claude.com/docs/en/models/haiku-4-5/overview"),
               .init(label: "models/haiku-4-5/migration-guide", url: "https://platform.claude.com/docs/en/models/haiku-4-5/migration-guide"),
               .init(label: "build-with-claude/effort", url: "https://platform.claude.com/docs/en/build-with-claude/effort"),
               .init(label: "models/overview", url: "https://platform.claude.com/docs/en/models/overview"),
           ]),
    // GPT-6 Sol and Luna replaced the GPT-5.6 tiers on 24 Sep 2026. OpenAI publishes no GPT-6 Terra.
    Target(id: "sol", label: "GPT-6 Sol",
           fileName: "openai-prompting-guide.md",
           generalHeader: "## General principles (current GPT models)",
           specificHeader: "## GPT-6 Sol-specific notes",
           sourceDate: "24 Sep 2026",
           confidencePercent: 80,
           confidenceNote: "Primary docs. OpenAI's one GPT-6 guide covers the whole family, and its behaviour notes were observed on Astra, not on this model.",
           confidenceCriteria: [
               .init(label: "Dedicated per-tier prompting page exists", met: false),
               .init(label: "Model overview / pricing page read", met: true),
               .init(label: "Tier-to-tier behavior split published", met: false),
               .init(label: "Family prompting guide covered", met: true),
           ],
           sourceLinks: [
               .init(label: "guides/latest-model", url: "https://developers.openai.com/api/docs/guides/latest-model"),
               .init(label: "guides/reasoning", url: "https://developers.openai.com/api/docs/guides/reasoning"),
               .init(label: "guides/prompt-engineering", url: "https://developers.openai.com/api/docs/guides/prompt-engineering"),
               .init(label: "models/gpt-6-sol", url: "https://developers.openai.com/api/docs/models/gpt-6-sol"),
           ]),
    Target(id: "luna", label: "GPT-6 Luna",
           fileName: "openai-prompting-guide.md",
           generalHeader: "## General principles (current GPT models)",
           specificHeader: "## GPT-6 Luna-specific notes",
           sourceDate: "24 Sep 2026",
           confidencePercent: 80,
           confidenceNote: "Primary docs. OpenAI's one GPT-6 guide covers the whole family, and its behaviour notes were observed on Astra, not on this model.",
           confidenceCriteria: [
               .init(label: "Dedicated per-tier prompting page exists", met: false),
               .init(label: "Model overview / pricing page read", met: true),
               .init(label: "Tier-to-tier behavior split published", met: false),
               .init(label: "Family prompting guide covered", met: true),
           ],
           sourceLinks: [
               .init(label: "guides/latest-model", url: "https://developers.openai.com/api/docs/guides/latest-model"),
               .init(label: "guides/reasoning", url: "https://developers.openai.com/api/docs/guides/reasoning"),
               .init(label: "guides/prompt-engineering", url: "https://developers.openai.com/api/docs/guides/prompt-engineering"),
               .init(label: "models/gpt-6-luna", url: "https://developers.openai.com/api/docs/models/gpt-6-luna"),
           ]),
    Target(id: "astra", label: "GPT-6 Astra",
           fileName: "openai-prompting-guide.md",
           generalHeader: "## General principles (current GPT models)",
           specificHeader: "## GPT-6 Astra-specific notes",
           sourceDate: "24 Sep 2026",
           confidencePercent: 85,
           confidenceNote: "Primary docs. The GPT-6 guide's behaviour notes were observed on Astra itself; little independent field verification yet.",
           confidenceCriteria: [
               .init(label: "Dedicated prompting page exists", met: true),
               .init(label: "Model overview / pricing page read", met: true),
               .init(label: "Migration guidance read", met: true),
               .init(label: "Independent field verification", met: false),
           ],
           sourceLinks: [
               .init(label: "guides/prompt-engineering", url: "https://developers.openai.com/api/docs/guides/prompt-engineering"),
               .init(label: "guides/reasoning", url: "https://developers.openai.com/api/docs/guides/reasoning"),
               .init(label: "guides/latest-model", url: "https://developers.openai.com/api/docs/guides/latest-model"),
               .init(label: "models/gpt-6-astra", url: "https://developers.openai.com/api/docs/models/gpt-6-astra"),
           ]),
]

let skillDir = ("~/.claude/skills/rosetta-prompt" as NSString).expandingTildeInPath
let referenceDir = (skillDir as NSString).appendingPathComponent("reference")
let checkerPath = (skillDir as NSString).appendingPathComponent("scripts/check_rewrite.py")

enum ReferenceError: Error, LocalizedError {
    case fileMissing(String)
    case sectionMissing(String, String)

    var errorDescription: String? {
        switch self {
        case .fileMissing(let path):
            return "Reference file not found: \(path). The /rosetta-prompt skill needs to exist first."
        case .sectionMissing(let header, let file):
            return "Section \"\(header)\" not found in \(file). The reference file may have changed."
        }
    }
}

func loadSection(fileName: String, header: String) throws -> String {
    let path = (referenceDir as NSString).appendingPathComponent(fileName)
    guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
        throw ReferenceError.fileMissing(path)
    }
    let lines = content.components(separatedBy: "\n")
    guard let startIdx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == header }) else {
        throw ReferenceError.sectionMissing(header, fileName)
    }
    var endIdx = lines.count
    for i in (startIdx + 1)..<lines.count {
        if lines[i].hasPrefix("## ") {
            endIdx = i
            break
        }
    }
    return lines[startIdx..<endIdx].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Token estimation
//
// Approximate on purpose. Neither provider exposes a local tokenizer here, and the usual
// four-characters-per-token rule is close enough for English prose and prompt-shaped text to be
// worth showing. Every number derived from this is prefixed with a tilde in the UI so it never
// reads as a billed figure.

enum TokenEstimate {
    static func count(_ text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return max(1, Int((Double(trimmed.count) / 4.0).rounded()))
    }

    static func format(_ n: Int) -> String {
        if n < 1000 { return "\(n)" }
        return String(format: "%.1fk", Double(n) / 1000.0)
    }
}

// Guidance sections are stable for the life of a launch, so measure each target once.
@MainActor
enum GuidanceSize {
    private static var cache: [String: Int] = [:]

    static func tokens(for target: Target) -> Int {
        if let cached = cache[target.id] { return cached }
        let general = (try? loadSection(fileName: target.fileName, header: target.generalHeader)) ?? ""
        let specific = (try? loadSection(fileName: target.fileName, header: target.specificHeader)) ?? ""
        let value = TokenEstimate.count(general) + TokenEstimate.count(specific)
        cache[target.id] = value
        return value
    }
}

// MARK: - Running the translation

enum ClaudeRunner {
    /// No connectors and no auto-memory. Together with `--setting-sources ""` below, nothing from
    /// the user's own Claude Code setup (CLAUDE.md, memory, hooks) rides along with a rewrite.
    static let noToolsEnv = ["ENABLE_CLAUDEAI_MCP_SERVERS": "false",
                             "CLAUDE_CODE_DISABLE_AUTO_MEMORY": "1"]

    static func findExecutable() -> String? {
        let candidates = [
            NSHomeDirectory() + "/.local/bin/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
        ]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            return path
        }
        return nil
    }

    static func run(prompt: String, model: String, effort: String) async throws -> String {
        guard let exe = findExecutable() else {
            throw NSError(domain: "RosettaPrompt", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not find the claude CLI. Checked ~/.local/bin, /opt/homebrew/bin, /usr/local/bin."
            ])
        }
        // -p is explicit print mode. It was being inferred from the positional prompt before,
        // which worked but left --output-format and --no-session-persistence on undocumented
        // ground, since both are documented as print-only.
        //
        // --no-session-persistence is the important one. This is a stateless one-shot call
        // that can never be resumed, so writing a session record for it is pure overhead. It
        // also stops the CLI doing project bookkeeping against ~/.claude.json, whose project
        // list points into ~/Documents. That file access is attributed to this app, which has
        // no Documents permission, which is what triggers the macOS privacy prompt on every
        // translate. And it keeps these rewrites out of `claude --resume`.
        //
        // No tools at all (harness L3): a rewrite reads nothing and changes nothing. `--tools ""`
        // drops the built-ins, `--strict-mcp-config` drops plugin MCP servers, and the environment
        // switch keeps the claude.ai connectors, such as Gmail, from connecting.
        //
        // No personal context either. `--setting-sources ""` skips the user, project and local
        // settings, which is what loads the global CLAUDE.md and runs prompt hooks; without it a
        // rewrite carried the user's own name and standing rules to the model and into the output.
        let outcome = try await runProcess(exe: exe, arguments: [
            "-p", prompt,
            "--model", model,
            "--effort", effort,
            "--output-format", "text",
            "--no-session-persistence",
            "--tools", "",
            "--strict-mcp-config",
            "--setting-sources", "",
        ], extraEnv: noToolsEnv)
        if outcome.status != 0 {
            let message = outcome.err.isEmpty ? "claude exited with status \(outcome.status)" : outcome.err
            throw NSError(domain: "RosettaPrompt", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return outcome.out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Runs a child process off the main thread with the environment every child of this app needs.
func runProcess(exe: String, arguments: [String], extraEnv: [String: String] = [:]) async throws
    -> (status: Int32, out: String, err: String) {
    try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: exe)
            process.arguments = arguments
            // Pin cwd outside ~/Documents, ~/Desktop, ~/Downloads. A GUI-launched app can inherit
            // a working directory under one of those, and claude's project/CLAUDE.md discovery
            // walks upward from cwd, which then trips the macOS protected-folder permission
            // prompt for a one-shot stateless call that needs none of that discovery anyway.
            process.currentDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())

            var env = ProcessInfo.processInfo.environment
            let extraPaths = [NSHomeDirectory() + "/.local/bin", "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
            env["PATH"] = extraPaths.joined(separator: ":") + ":" + (env["PATH"] ?? "")
            // currentDirectoryURL above sets the real cwd, but a stale PWD inherited from
            // whatever launched the app would still point a child at ~/Documents. Pin both.
            env["PWD"] = NSTemporaryDirectory()
            env.removeValue(forKey: "OLDPWD")
            env.merge(extraEnv) { _, new in new }
            process.environment = env

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.standardInput = FileHandle.nullDevice

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }
            // Drain both pipes before waiting. The checker prints a few KB of JSON, and a full
            // pipe buffer would otherwise leave the child blocked on write forever.
            let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            continuation.resume(returning: (status: process.terminationStatus,
                                            out: String(data: outData, encoding: .utf8) ?? "",
                                            err: String(data: errData, encoding: .utf8) ?? ""))
        }
    }
}

// MARK: - Eval checks
//
// Every rewrite goes through scripts/check_rewrite.py in the skill folder before it is shown:
// code checks first, then a Sonnet 5 judge. The criteria live in reference/rewrite-evals.md, so
// they can change without a rebuild. The judge is advisory until its calibration set arms it
// (the harness rule in reference/rewrite-evals.md), which the script decides, not the app.

struct CheckFinding: Decodable {
    let rule: String
    let text: String
    let fixHint: String?

    enum CodingKeys: String, CodingKey {
        case rule, text
        case fixHint = "fix_hint"
    }
}

struct CheckResult: Decodable {
    let approved: Bool
    let retry: Bool
    let maxAttempts: Int
    let judgeArmed: Bool
    let blocking: [CheckFinding]
    let advisory: [CheckFinding]
    let feedback: String
    let notes: [String]

    enum CodingKeys: String, CodingKey {
        case approved, retry, blocking, advisory, feedback, notes
        case maxAttempts = "max_attempts"
        case judgeArmed = "judge_armed"
    }
}

enum EvalRunner {
    /// The checker reads its inputs from files. Returns the file arguments for them, with
    /// `--context` only when there is context.
    private static func writeInputs(to dir: URL, target: Target, original: String, rewrite: String,
                                    context: String) throws -> [String] {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let files = ["original.txt": original, "rewrite.txt": rewrite, "context.txt": context]
        for (name, text) in files {
            try text.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        var args = ["--target", target.id,
                    "--original", dir.appendingPathComponent("original.txt").path,
                    "--rewrite", dir.appendingPathComponent("rewrite.txt").path]
        if !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args += ["--context", dir.appendingPathComponent("context.txt").path]
        }
        return args
    }

    private static func tempDir() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("rosetta-\(UUID().uuidString)", isDirectory: true)
    }

    /// Nil result means the checks could not run. That never blocks a rewrite; the reason is shown.
    static func check(target: Target, original: String, rewrite: String, context: String,
                      attempt: Int) async -> (result: CheckResult?, problem: String) {
        guard FileManager.default.fileExists(atPath: checkerPath) else {
            return (nil, "checker not found at \(checkerPath)")
        }
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        do {
            let args = [checkerPath, "check"]
                + (try writeInputs(to: dir, target: target, original: original, rewrite: rewrite, context: context))
                + ["--attempt", String(attempt)]
            var extraEnv: [String: String] = [:]
            if let claude = ClaudeRunner.findExecutable() { extraEnv["ROSETTA_CLAUDE_BIN"] = claude }
            let outcome = try await runProcess(exe: "/usr/bin/python3", arguments: args, extraEnv: extraEnv)
            // Exit 0 is approved and 1 is rejected; both print the verdict JSON.
            guard outcome.status == 0 || outcome.status == 1,
                  let data = outcome.out.data(using: .utf8),
                  let result = try? JSONDecoder().decode(CheckResult.self, from: data) else {
                let why = outcome.err.trimmingCharacters(in: .whitespacesAndNewlines)
                return (nil, why.isEmpty ? "checker exited with status \(outcome.status)" : why)
            }
            return (result, "")
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    /// Files a rewrite the user judged wrong as a rejected judge calibration case (harness L5). Not a
    /// replay case: replay runs code checks only, and a rewrite that passed them would fail the
    /// replay gate forever. Returns the line to show.
    static func saveRejectedCase(target: Target, original: String, rewrite: String, context: String,
                                 why: String) async -> String {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        do {
            let args = [checkerPath, "save-case"]
                + (try writeInputs(to: dir, target: target, original: original, rewrite: rewrite, context: context))
                + ["--expected", "Rejected", "--why", why, "--dest", "calibration"]
            let outcome = try await runProcess(exe: "/usr/bin/python3", arguments: args)
            guard outcome.status == 0 else {
                let why = outcome.err.trimmingCharacters(in: .whitespacesAndNewlines)
                return "Not saved: \(why.isEmpty ? "save-case exited with status \(outcome.status)" : why)"
            }
            let rejectedDir = (skillDir as NSString).appendingPathComponent("evals/calibration/rejected")
            let count = ((try? FileManager.default.contentsOfDirectory(atPath: rejectedDir)) ?? [])
                .filter { $0.hasSuffix(".json") }.count
            return "Saved. \(count) rejected calibration case\(count == 1 ? "" : "s") on file."
        } catch {
            return "Not saved: \(error.localizedDescription)"
        }
    }

    /// The one-line status shown above the result, in the same words the skill uses.
    static func summary(_ result: CheckResult?, problem: String, attempts: Int) -> String {
        let tries = "after \(attempts) attempt\(attempts == 1 ? "" : "s")"
        guard let result else { return "Checks unavailable: \(problem)" }
        if !result.approved {
            return "Checks FAILED: \(result.blocking.map(\.rule).joined(separator: ", ")) \(tries)"
        }
        let notes = result.advisory.filter { $0.rule.hasPrefix("judge.") }.count
        return notes == 0
            ? "Checks passed \(tries)"
            : "Checks passed, \(notes) judge note\(notes == 1 ? "" : "s") \(tries)"
    }
}

func buildRequest(target: Target, messyPrompt: String, extraContext: String, suggestedEffort: String?,
                  retry: (draft: String, feedback: String)? = nil) throws -> String {
    let general = try loadSection(fileName: target.fileName, header: target.generalHeader)
    let specific = try loadSection(fileName: target.fileName, header: target.specificHeader)
    // Optional: an older reference file may not carry this section, and a rewrite without it is
    // still a valid rewrite, so a missing section must not fail the run.
    let avoid = (try? loadSection(fileName: target.fileName, header: target.avoidHeader)) ?? ""
    let avoidBlock = avoid.isEmpty ? "" : "\n\n" + avoid

    // Both reference guides instruct the rewrite to name the effort level a task's real difficulty
    // suggests, since effort is set by the caller rather than baked into prompt text. The app knows
    // that number now, so it stops withholding it.
    let effortBlock: String
    if let suggestedEffort {
        effortBlock = """

    <suggested_effort>
    A local difficulty score puts this task at effort level "\(suggestedEffort)" on \(target.label). If, and only if, the guidance above says to flag the effort a task warrants, state that briefly in the rewritten prompt. Never invent a different level, and never add a line about effort if the guidance does not call for one.
    </suggested_effort>
    """
    } else {
        effortBlock = ""
    }

    let trimmedContext = extraContext.trimmingCharacters(in: .whitespacesAndNewlines)
    let contextBlock = trimmedContext.isEmpty ? "" : """

    <established_context>
    \(trimmedContext)
    </established_context>
    """

    // Bounce loop (harness L4): a failed draft comes back with the check IDs and reasons.
    let retryBlock: String
    if let retry {
        retryBlock = """

    <previous_attempt_feedback>
    Your previous draft failed the checks listed below. Fix exactly these points and keep everything else as it was.
    <previous_draft>
    \(retry.draft)
    </previous_draft>
    <failed_checks>
    \(retry.feedback)
    </failed_checks>
    </previous_attempt_feedback>
    """
    } else {
        retryBlock = ""
    }

    return """
    You are rewriting a disorganized user prompt into a clear, well-structured prompt for a specific target model, using the guidance below.

    <target_model>\(target.label)</target_model>

    <prompting_guidance>
    \(general)

    \(specific)\(avoidBlock)
    </prompting_guidance>
    \(effortBlock)\(contextBlock)

    <messy_prompt>
    \(messyPrompt)
    </messy_prompt>

    <house_style>
    Never use an em dash or an en dash anywhere in your output. Not in the prose, not inside examples, not in headings. Use a comma, a colon, a full stop, or recast the sentence. This is a hard rule with no exceptions, and it overrides any habit or house style implied by the guidance above. A hyphen inside a genuine compound word is fine.
    </house_style>

    <success_criteria>
    The rewrite is checked before anyone sees it. It passes when it asks for the same task, deliverable and audience as the messy prompt; keeps every stated constraint; adds no names, numbers, files or facts that are not in the messy prompt or established context; makes clear what a finished answer looks like; and uses no more structure than the task needs. Only where the task carries that risk, it also lets the model say it lacks information and ground its claims in the given material, defines a repeatable output format precisely, and keeps secrets the task does not need out of the prompt. It fails on any em or en dash, a placeholder slot such as [NAME] or TBD, a lead-in line or closing note, or a code fence around the whole output.
    </success_criteria>
    \(retryBlock)

    Apply only the techniques from the guidance that this prompt's complexity actually warrants. If established_context is present, use it to fill in specifics rather than leaving placeholders or guessing. Output exactly one thing: the rewritten prompt itself. No preamble, no explanation, no markdown code fence wrapper, nothing before or after it.
    """
}

// MARK: - Rubric file
//
// The scoring directives live in model-selection.md alongside the prompting guides, cited and
// dated, so the judgment the app applies can be read and argued with without a rebuild. Every
// lookup takes a fallback: a missing or malformed file degrades to the values compiled in here,
// it never breaks the app.
//
// The shipped file holds neutral defaults. A user's own examples and signals go in
// model-selection.local.md beside it, which stays on their machine (it is gitignored). Any table
// named in the local file replaces the default table of the same name, whole.

@MainActor
enum Rubric {
    private static var tables: [String: [(String, String)]] = [:]
    private static var loaded = false

    static let fileName = "model-selection.md"
    static let localFileName = "model-selection.local.md"

    private static func load() {
        guard !loaded else { return }
        loaded = true
        for name in [fileName, localFileName] {
            let path = (referenceDir as NSString).appendingPathComponent(name)
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            tables.merge(parse(content)) { _, local in local }
        }
    }

    private static func parse(_ content: String) -> [String: [(String, String)]] {
        var tables: [String: [(String, String)]] = [:]
        var current: String?
        var inFence = false
        for raw in content.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if !inFence {
                if line.hasPrefix("```rubric") { inFence = true; current = nil }
                continue
            }
            if line.hasPrefix("```") { inFence = false; current = nil; continue }
            if line.hasPrefix("@table ") {
                let name = String(line.dropFirst("@table ".count)).trimmingCharacters(in: .whitespaces)
                current = name
                tables[name] = []
                continue
            }
            guard let name = current, !line.isEmpty, !line.hasPrefix("#") else { continue }
            if let cut = line.firstIndex(where: { $0 == "|" || $0 == "=" }) {
                let key = String(line[line.startIndex..<cut]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: cut)...]).trimmingCharacters(in: .whitespaces)
                if !key.isEmpty { tables[name]?.append((key, value)) }
            } else {
                tables[name]?.append((line, ""))
            }
        }
        return tables
    }

    /// Every row of a table as key/value pairs, or the fallback when the table is absent or empty.
    static func pairs(_ table: String, fallback: [(String, String)]) -> [(String, String)] {
        load()
        let rows = tables[table] ?? []
        return rows.isEmpty ? fallback : rows
    }

    /// Just the keys, for tables that are a plain list.
    static func keys(_ table: String, fallback: [String]) -> [String] {
        load()
        let rows = tables[table] ?? []
        return rows.isEmpty ? fallback : rows.map(\.0)
    }

    static func value(_ table: String, _ key: String, fallback: String) -> String {
        load()
        return (tables[table] ?? []).first { $0.0 == key }?.1 ?? fallback
    }

    static func int(_ table: String, _ key: String, fallback: Int) -> Int {
        Int(value(table, key, fallback: "")) ?? fallback
    }

    /// A comma-separated row, used for the model ladders.
    static func list(_ table: String, _ key: String, fallback: [String]) -> [String] {
        let raw = value(table, key, fallback: "")
        let parts = raw.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? fallback : parts
    }
}

// MARK: - Model-selection advice
//
// Deliberately a local scoring program, not a model call. Asking a model whether a model is
// overkill would bill the user every time they pressed Translate to find out they were overspending.
// Everything below runs in-process, costs nothing, returns instantly, and shows which signals
// fired so the verdict can be argued with rather than trusted.

enum Verdict: String {
    case right
    /// One class of daylight. Anthropic's documented first lever is an effort sweep on the model
    /// you already have, not a tier change, so this keeps the model and drops the effort. Nothing
    /// is wasted by proceeding: the rewrite is identical for the same target.
    case lowerEffort
    /// Two classes or more. Worth changing model, and worth stopping before the rewrite is built,
    /// because a rewrite is assembled from its target's own prompting guidance.
    case wrongSize
    case underpowered

    var badge: String {
        switch self {
        case .right: return "GOOD FIT"
        case .lowerEffort: return "LESS EFFORT"
        case .wrongSize: return "WRONG SIZE"
        case .underpowered: return "TOO LIGHT"
        }
    }

    /// Only a real model mismatch is worth interrupting for.
    var needsDecision: Bool {
        self == .wrongSize || self == .underpowered
    }

    var tint: Color {
        switch self {
        case .right: return Color(red: 0.16, green: 0.55, blue: 0.30)
        case .lowerEffort: return Color(red: 0.72, green: 0.42, blue: 0.02)
        case .wrongSize: return Color(red: 0.72, green: 0.42, blue: 0.02)
        case .underpowered: return Color(red: 0.72, green: 0.20, blue: 0.16)
        }
    }
}

struct Advice {
    let model: Target
    let effort: String
    let verdict: Verdict
    let signals: [String]
    let score: Int
    let highStakes: Bool
    let expectedOutputTokens: Int
    /// One line on what the recommended tier costs and is for, from the rubric file.
    let positioning: String
}

@MainActor
enum Advisor {
    // Weight class, cheapest to dearest, used only to compare the recommendation against what is
    // currently selected. GPT-6 has three models, so Sol covers classes 2 and 3 (see the rubric's ladder).
    static func weightClass(_ target: Target) -> Int {
        let builtIn = ["haiku": 1, "luna": 1, "sonnet": 2, "opus": 3, "sol": 3, "fable": 4, "astra": 4]
        return Rubric.int("class", target.id, fallback: builtIn[target.id] ?? 2)
    }

    private static func target(id: String) -> Target {
        targets.first { $0.id == id } ?? targets[2]
    }

    /// Pick the model of the right size, staying inside the family already selected. Switching a
    /// Claude prompt to a GPT model is a decision about vendor and tooling, not about difficulty,
    /// so this never makes it.
    private static func model(forClass cls: Int, family: String) -> Target {
        let ladder = family == "openai"
            ? Rubric.list("ladder", "openai", fallback: ["luna", "sol", "sol", "astra"])
            : Rubric.list("ladder", "anthropic", fallback: ["haiku", "sonnet", "opus", "fable"])
        let idx = min(max(cls, 1), ladder.count) - 1
        return target(id: ladder[idx])
    }

    /// Effort for the rewrite call itself, which is a different job from the task being described.
    /// It tracks the task's difficulty but is capped at `high`: a rewrite is one bounded generation,
    /// and the docs reserve `xhigh` for "long-running agentic and coding tasks (over 30 minutes)".
    /// Capping guarantees this can only ever match or undercut the old hardcoded `high`.
    static func engineEffort(for advice: Advice?) -> String {
        guard let advice else { return "high" }
        switch advice.effort {
        case "low", "medium": return advice.effort
        default: return "high"
        }
    }

    /// Effort for a difficulty class, per the levels table in the rubric file, which quotes
    /// Anthropic's own stated use case for each level.
    private static func effort(forClass cls: Int) -> String {
        let builtIn = [1: "low", 2: "medium", 3: "high", 4: "xhigh"]
        return Rubric.value("effort", String(cls), fallback: builtIn[cls] ?? "high")
    }

    /// Words of the task, lowercased, split on anything that is not a letter or digit. Matching
    /// against these rather than the raw string is what keeps "improve" out of "prove", "syntax"
    /// out of "tax" and "information" out of "format".
    private static func words(_ text: String) -> [String] {
        text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }

    /// A needle containing a space or hyphen is a phrase and is matched against the whole string.
    /// A single word is matched as a word prefix, so stems like "optimi" or "negotiat" still catch
    /// every ending without catching unrelated words that merely contain those letters.
    private static func matches(_ needle: String, text: String, words: [String]) -> Bool {
        if needle.contains(" ") || needle.contains("-") {
            return text.contains(needle)
        }
        if exactNeedles.contains(needle) {
            return words.contains(needle)
        }
        return words.contains { $0.hasPrefix(needle) }
    }

    /// Needles too short to prefix-match safely. "tax" as a prefix also claims "taxonomy".
    private static var exactNeedles: Set<String> {
        Set(Rubric.keys("exact", fallback: ["tax", "taxes", "plan", "plans"]))
    }

    // The signal tables, the thresholds and the ladders all live in model-selection.md. The
    // literals below are the fallback if that file is missing, so the app degrades rather than
    // breaking. Stems are used where a word has several endings ("optimi" catches optimise and
    // optimize); see the matcher above for how a stem is kept from over-claiming.
    private static var heavySignals: [(needle: String, label: String)] {
        Rubric.pairs("heavy", fallback: [
            ("architect", "architecture work"), ("trade-off", "weighing trade-offs"), ("tradeoff", "weighing trade-offs"),
            ("refactor", "refactoring"), ("debug", "debugging"), ("root cause", "root-cause work"),
            ("why does", "diagnosis"), ("why is", "diagnosis"), ("diagnos", "diagnosis"),
            ("prove", "proof or derivation"), ("derive", "proof or derivation"),
            ("optimi", "optimisation"), ("migrat", "migration"),
            ("strategy", "strategy"), ("strategi", "strategy"),
            ("evaluate", "evaluation"), ("critique", "evaluation"), ("pressure-test", "evaluation"),
            ("compare", "comparison"), ("decide", "a decision"), ("recommend", "a recommendation"),
            ("figure out", "open-ended"), ("work out", "open-ended"), ("help me think", "open-ended"),
            ("edge case", "edge cases"), ("across multiple", "multi-part"), ("end to end", "multi-part"),
            ("bug", "debugging"), ("crash", "debugging"), ("broken", "debugging"), ("timeout", "debugging"),
            ("traceback", "debugging"), ("stack trace", "debugging"), ("keeps dying", "debugging"),
            ("keeps failing", "debugging"), ("keeps crashing", "debugging"), ("not working", "debugging"),
            ("doesn't work", "debugging"), ("stops working", "debugging"),
        ])
    }

    private static var lightSignals: [(needle: String, label: String)] {
        Rubric.pairs("light", fallback: [
            ("extract", "extraction"), ("classify", "classification"), ("classifies", "classification"), ("categor", "classification"),
            ("format", "formatting"), ("reformat", "formatting"), ("tidy", "tidying"),
            ("clean up", "tidying"), ("spell", "proofreading"), ("grammar", "proofreading"),
            ("proofread", "proofreading"), ("shorten", "trimming"), ("summar", "summarising"),
            ("list of", "listing"), ("bullet", "listing"), ("rename", "renaming"),
            ("convert", "conversion"), ("translate to", "translation"),
        ])
    }

    /// Stakes, not difficulty. This app's rule, not Anthropic's: money, legal standing, immigration
    /// status and security go to a top-tier model at high effort however simple the question reads,
    /// because the cost of being wrong is not measured in tokens. These floor the class rather than
    /// scoring.
    private static var stakesSignals: [(needle: String, label: String)] {
        Rubric.pairs("stakes", fallback: [
            ("legal", "legal standing at stake"), ("contract", "contract terms"),
            ("tax", "tax exposure"), ("taxes", "tax exposure"),
            ("negotiat", "a negotiation"), ("salary", "money at stake"), ("compensation", "money at stake"),
            ("invoice", "money at stake"), ("visa", "immigration status at stake"),
            ("immigration", "immigration status at stake"),
            ("security", "security exposure"), ("vulnerab", "security exposure"), ("credential", "security exposure"),
        ])
    }

    /// Phrases that hold a stakes word without the stakes, such as "schema contracts". They are
    /// blanked out before the stakes list is matched.
    private static var notStakes: [String] {
        Rubric.keys("not-stakes", fallback: ["schema contract", "data contract", "api contract",
                                             "interface contract", "code contract", "contract test"])
    }

    private static var generativeSignals: [String] {
        Rubric.keys("generative", fallback: ["write", "draft", "compose", "essay", "article", "blog",
                                            "memo", "proposal", "build", "implement", "generate",
                                            "create", "outline"])
    }

    /// Scores the messy prompt together with any extra context, since the context is part of what
    /// the finished prompt will ask the model to work through.
    static func assess(task: String, context: String, selected: Target) -> Advice? {
        guard !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let raw = (task + "\n\n" + context).trimmingCharacters(in: .whitespacesAndNewlines)
        let text = raw.lowercased()

        var score = 0
        var signals: [String] = []

        func note(_ label: String) {
            if !signals.contains(label) { signals.append(label) }
        }

        // Length. A long brief is usually a bigger job, but only weakly: a long paste can also be
        // one simple instruction plus a lot of pasted material.
        if raw.count > Rubric.int("thresholds", "verylongbrief", fallback: 4000) {
            score += 2
            note("very long brief")
        } else if raw.count > Rubric.int("thresholds", "longbrief", fallback: 1200) {
            score += 1
            note("long brief")
        } else if raw.count < Rubric.int("thresholds", "shortask", fallback: 220) {
            score -= 1
            note("short ask")
        }

        // Code. Fenced blocks or a high symbol density mean the answer has to hold real structure.
        let symbols = text.filter { "{}[]();<>=".contains($0) }.count
        if text.contains("```") || (raw.count > 200 && Double(symbols) / Double(raw.count) > 0.03) {
            score += 2
            note("contains code")
        }

        // Multi-step structure: numbered steps, or several distinct questions.
        let numberedSteps = raw.components(separatedBy: "\n").filter {
            let l = $0.trimmingCharacters(in: .whitespaces)
            return l.count > 2 && l.first?.isNumber == true && (l.dropFirst().first == "." || l.dropFirst().first == ")")
        }.count
        if numberedSteps >= 3 {
            score += 2
            note("multi-step, \(numberedSteps) steps")
        } else if text.contains(" then ") || text.contains("step 1") || text.contains("first,") {
            score += 1
            note("sequenced work")
        }
        let questions = text.filter { $0 == "?" }.count
        if questions >= 3 {
            score += 1
            note("\(questions) separate questions")
        }

        let tokens = words(text)

        // Heavy phrases stack fast on a rambling brief, so the word list is capped. Reaching the
        // top class has to be earned by length, code or structure as well, not by vocabulary alone.
        var wordScore = 0
        for signal in heavySignals where matches(signal.needle, text: text, words: tokens) {
            wordScore += 2
            note(signal.label)
        }
        score += min(wordScore, Rubric.int("thresholds", "wordcap", fallback: 6))

        for signal in lightSignals where matches(signal.needle, text: text, words: tokens) {
            score -= 1
            note(signal.label)
        }

        var stakesText = text
        for phrase in notStakes {
            stakesText = stakesText.replacingOccurrences(of: phrase, with: " ")
        }
        let stakesTokens = words(stakesText)
        var stakeLabels: [String] = []
        for signal in stakesSignals where matches(signal.needle, text: stakesText, words: stakesTokens) {
            if !stakeLabels.contains(signal.label) { stakeLabels.append(signal.label) }
        }
        let highStakes = !stakeLabels.isEmpty
        // Stakes lead, then content signals, then the length notes. The panel shows only the first
        // one, and "short ask" explains far less about a task than "extraction" does.
        let lengthNotes = ["very long brief", "long brief", "short ask"]
        let rest = signals.filter { !stakeLabels.contains($0) }
        signals = stakeLabels
            + rest.filter { !lengthNotes.contains($0) }
            + rest.filter { lengthNotes.contains($0) }

        let class2 = Rubric.int("thresholds", "class2from", fallback: 2)
        let class3 = Rubric.int("thresholds", "class3from", fallback: 6)
        let class4 = Rubric.int("thresholds", "class4from", fallback: 10)

        var needed: Int
        switch score {
        case ..<class2: needed = 1
        case class2..<class3: needed = 2
        case class3..<class4: needed = 3
        default: needed = 4
        }
        if highStakes { needed = max(needed, 3) }

        var chosenEffort = effort(forClass: needed)
        if highStakes, chosenEffort == "low" || chosenEffort == "medium" { chosenEffort = "high" }

        let family = (selected.fileName == "openai-prompting-guide.md") ? "openai" : "anthropic"
        let selectedClass = weightClass(selected)
        let gap = selectedClass - needed

        // The recommendation comes from the task alone, so the same prompt gets the same model and
        // effort whatever is selected. The selection only sets the verdict: one class of daylight
        // is an effort sweep on the model you have, two is a genuine mismatch worth interrupting.
        let recommended = model(forClass: needed, family: family)
        let verdict: Verdict
        if gap >= 2 {
            verdict = .wrongSize
        } else if gap == 1 {
            verdict = .lowerEffort
        } else if gap <= -1 {
            verdict = .underpowered
        } else {
            verdict = .right
        }

        return Advice(model: recommended,
                      effort: chosenEffort,
                      verdict: verdict,
                      signals: Array(signals.prefix(4)),
                      score: score,
                      highStakes: highStakes,
                      expectedOutputTokens: outputGuess(text: text,
                                                        inputTokens: TokenEstimate.count(raw),
                                                        score: score,
                                                        highStakes: highStakes),
                      positioning: Rubric.value("positioning", recommended.id, fallback: ""))
    }

    /// Rough guess at how long the answer runs. Answer length tracks the shape of the task far more
    /// than the length of the ask: "write a blog post" is eight words in and a thousand tokens out,
    /// while an extraction is bounded by what it was given. So transforms scale with the input and
    /// everything else starts from a base for its kind.
    private static func outputGuess(text: String, inputTokens: Int, score: Int, highStakes: Bool) -> Int {
        let tokens = words(text)
        let isTransform = lightSignals.contains { matches($0.needle, text: text, words: tokens) }
        let isGenerative = generativeSignals.contains { matches($0, text: text, words: tokens) }

        var guess: Int
        if isTransform && !isGenerative {
            guess = Int(Double(inputTokens) * 0.7)
        } else if isGenerative {
            guess = 900 + inputTokens / 2
        } else if score >= 6 || highStakes {
            guess = 1400 + inputTokens / 2
        } else {
            guess = 500 + inputTokens / 2
        }
        return min(max(guess, 100), 8000)
    }
}

// MARK: - UI

@MainActor
final class TranslatorState: ObservableObject {
    // Editing the task or changing the target invalidates any verdict on screen, so both clear it.
    // A guide that outlives the thing it judged is worse than no guide.
    @Published var messyPrompt: String = "" { didSet { clearAdvice() } }
    @Published var extraContext: String = "" { didSet { clearAdvice() } }
    @Published var selectedTarget: Target = targets[1] { didSet { clearAdvice() } } // Opus 5.5 default: general purpose, no assumed audience
    @Published var result: String = ""
    @Published var hoveredRung: String?  // the guide ladder rung under the pointer; see GuidePanel
    @Published var isRunning: Bool = false
    @Published var errorText: String = ""
    /// What the run is doing right now: rewriting, checking, or retrying.
    @Published var status: String = ""
    /// One line on how the result fared against the eval checks, plus the findings behind it.
    @Published var checkSummary: String = ""
    @Published var checkPassed: Bool = true
    @Published var checkLines: [String] = []
    /// The five harness layers as they applied to the last run.
    @Published var phases: [PhaseStatus] = Phases.idle
    /// "This rewrite was wrong": the reason box, and the line saying whether the case was filed.
    @Published var reportingWrong = false
    @Published var wrongReason = ""
    @Published var caseStatus = ""
    /// Exactly what the last result was checked with, so a filed case matches what the judge saw
    /// even if the text boxes have been edited since.
    private var lastRun: (target: Target, original: String, rewrite: String, context: String)?

    @Published var advice: Advice?
    /// Set after every assessment, so the model and effort pick is on screen before anything is
    /// sent to a model. When it disagrees with the selected target this matters most: the rewrite
    /// is built out of the target's own prompting guidance, so generating it for Opus and then
    /// switching to Sonnet throws the entire call away.
    @Published var awaitingChoice: Bool = false
    /// Suppresses the didSet clearing while the state machine is deliberately reassigning things.
    private var mutating = false

    private func clearAdvice() {
        guard !mutating else { return }
        advice = nil
        awaitingChoice = false
    }

    /// Estimated tokens sent to the rewriting model on the next press of Translate.
    var translationInputTokens: Int {
        GuidanceSize.tokens(for: selectedTarget)
            + TokenEstimate.count(messyPrompt)
            + TokenEstimate.count(extraContext)
            + 120 // wrapper instructions and tags
    }

    /// Estimated tokens of the rewritten prompt, which becomes the input when the user runs it.
    var resultTokens: Int { TokenEstimate.count(result) }

    /// Assess first, always, and stop there. The model and effort pick is shown before any spend;
    /// the rewrite starts only when the user presses one of the guide's buttons.
    func translate() {
        guard !messyPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        errorText = ""
        result = ""

        mutating = true
        advice = Advisor.assess(task: messyPrompt, context: extraContext, selected: selectedTarget)
        mutating = false
        // Only a real model mismatch waits for a choice. Otherwise the effort pick is shown as
        // information and the rewrite starts on this same press.
        guard let advice else { return }
        if advice.verdict.needsDecision {
            awaitingChoice = true
        } else {
            rewrite(for: selectedTarget)
        }
    }

    /// Take the guide's recommendation: re-point the target, re-score against it, and rewrite once.
    /// Both the guide panel's "Use" button and the alert's "Switch to" button land here, so picking
    /// the suggested model is one click instead of a trip to the target menu and a second Translate.
    func acceptRecommendation() {
        guard let recommended = advice?.model else { return }
        mutating = true
        selectedTarget = recommended
        advice = Advisor.assess(task: messyPrompt, context: extraContext, selected: recommended)
        mutating = false
        awaitingChoice = false
        rewrite(for: recommended)
    }

    /// Rewrite for what is selected: the guide agreed with it, or the user overrode the guide.
    func rewriteAnyway() {
        awaitingChoice = false
        rewrite(for: selectedTarget)
    }

    /// The effort the rewrite call will actually run at. Shown in the panel before the user presses
    /// anything, so the price of the run is visible rather than implied.
    var engineEffort: String { Advisor.engineEffort(for: advice) }

    private func rewrite(for target: Target) {
        isRunning = true
        checkSummary = ""
        checkLines = []
        checkPassed = true
        phases = Phases.idle
        reportingWrong = false
        caseStatus = ""
        lastRun = nil
        let messy = messyPrompt
        let context = extraContext
        let effort = Advisor.engineEffort(for: advice)
        // Haiku 4.5 has no effort parameter, so the rewrite must never mention one.
        let suggested = target.id == "haiku" ? nil : advice?.effort
        // The Fable, Opus and Sonnet guides tell the rewriter to state this level, and the request
        // passes it on. The judge only sees the original and the context, so without this line it
        // reads the app's own number as invented and bounces a draft that passed every code check.
        let checkContext = suggested.map {
            context + "\n\nEffort level set by Rosetta Prompt's difficulty score for \(target.label): \($0). The rewrite may state it."
        } ?? context
        Task {
            do {
                // Harness L4 bounce loop: rewrite, check, and on a failed check send the draft back
                // with the reasons. The script sets the attempt cap; the last draft is always shown.
                var attempt = 1
                var retry: (draft: String, feedback: String)?
                var output = ""
                var check: (result: CheckResult?, problem: String) = (nil, "")
                while true {
                    self.status = attempt == 1 ? "Rewriting..." : "Retrying (\(attempt))..."
                    let request = try buildRequest(target: target,
                                                   messyPrompt: messy,
                                                   extraContext: context,
                                                   suggestedEffort: suggested,
                                                   retry: retry)
                    output = try await ClaudeRunner.run(prompt: request, model: "opus", effort: effort)
                    self.status = "Checking..."
                    check = await EvalRunner.check(target: target, original: messy, rewrite: output,
                                                   context: checkContext, attempt: attempt)
                    guard let found = check.result, found.retry, attempt < found.maxAttempts else { break }
                    retry = (draft: output, feedback: found.feedback)
                    attempt += 1
                }
                self.result = output
                self.lastRun = (target: target, original: messy, rewrite: output, context: checkContext)
                self.checkSummary = EvalRunner.summary(check.result, problem: check.problem, attempts: attempt)
                self.checkPassed = check.result?.approved ?? true
                self.phases = Phases.after(check.result, attempts: attempt)
                if let found = check.result {
                    self.checkLines = (found.blocking + found.advisory.filter { $0.rule.hasPrefix("judge.") })
                        .prefix(3)
                        .map { "\($0.rule): \($0.text)" }
                }
            } catch {
                self.errorText = error.localizedDescription
            }
            self.status = ""
            self.isRunning = false
        }
    }

    var canReportWrong: Bool { lastRun != nil && !isRunning }

    func saveWrongCase() {
        let why = wrongReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let run = lastRun, !why.isEmpty else { return }
        caseStatus = "Saving..."
        Task {
            self.caseStatus = await EvalRunner.saveRejectedCase(target: run.target, original: run.original,
                                                                rewrite: run.rewrite, context: run.context, why: why)
            if self.caseStatus.hasPrefix("Saved") {
                self.reportingWrong = false
                self.wrongReason = ""
            }
        }
    }

    func copyResult() {
        guard !result.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
    }
}

// The Claude mark's terracotta. One warm system, not two: the panel used to be amber and a
// second warm palette beside it just fought for attention.
let guideAccent = Color(red: 0.85, green: 0.47, blue: 0.34)

/// A rung on the capability ladder. Brightness and height both rise with capability, so the
/// ordering survives a colour-blind viewer and a bad monitor.
struct Rung: Identifiable {
    let id: String
    let label: String
    let target: Target?          // nil when the rung is a real model but not a rewrite target
    let index: Int               // 0 lowest, 3 highest

    var selectable: Bool { target != nil }
}

@MainActor
enum Ladder {
    static func rungs(for family: String) -> [Rung] {
        let ids = family == "openai"
            ? Rubric.list("guide-ladder", "openai", fallback: ["luna", "sol", "astra"])
            : Rubric.list("guide-ladder", "anthropic", fallback: ["haiku", "sonnet", "opus", "fable"])
        // Spread the rungs over the four heights and colours, so the family's top model always
        // gets the tallest, brightest bar. GPT-6 has three models: steps 0, 2 and 3.
        let last = max(ids.count - 1, 1)
        return ids.enumerated().map { idx, id in
            Rung(id: id,
                 label: Rubric.value("rung-label", id, fallback: id.capitalized),
                 target: targets.first { $0.id == id },
                 index: Int((Double(idx) * 3 / Double(last)).rounded()))
        }
    }

    /// Four steps of the accent, dimmest to brightest. Kept above mid-luminance at the bottom so
    /// the lowest rung stays legible on a dark background as well as a light one.
    static func colour(_ index: Int, family: String) -> Color {
        let coral: [Color] = [
            Color(red: 0.50, green: 0.30, blue: 0.24),
            Color(red: 0.63, green: 0.36, blue: 0.27),
            Color(red: 0.78, green: 0.44, blue: 0.32),
            Color(red: 0.94, green: 0.56, blue: 0.41),
        ]
        let slate: [Color] = [
            Color(red: 0.34, green: 0.36, blue: 0.39),
            Color(red: 0.48, green: 0.51, blue: 0.54),
            Color(red: 0.63, green: 0.66, blue: 0.69),
            Color(red: 0.82, green: 0.85, blue: 0.88),
        ]
        let ramp = family == "openai" ? slate : coral
        return ramp[min(max(index, 0), ramp.count - 1)]
    }

    static func height(_ index: Int) -> CGFloat { [9, 17, 26, 36][min(max(index, 0), 3)] }

    /// A row is "job; when it is worth paying for". A row without the second half shows alone.
    static func detail(_ id: String) -> [(job: String, why: String)] {
        (1...5).compactMap {
            let row = Rubric.value("detail", "\(id).\($0)", fallback: "")
            guard !row.isEmpty else { return nil }
            let parts = row.split(separator: ";", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            return (job: parts[0], why: parts.count > 1 ? parts[1] : "")
        }
    }
}

struct GuidePanel: View {
    @ObservedObject var state: TranslatorState
    /// Which rung the mouse is over. Nil falls back to the selected target, so the detail block is
    /// never empty and never changes height. A block that grew on hover would make the whole panel
    /// jump every time the pointer crossed it. It lives on TranslatorState, not in @State: the
    /// macOS 27 Command Line Tools ship without SwiftUI's @State macro plugin, so @State fails to build.
    private var hovered: String? { state.hoveredRung }

    private var family: String {
        state.selectedTarget.fileName == "openai-prompting-guide.md" ? "openai" : "anthropic"
    }

    private var focused: Rung? {
        let rungs = Ladder.rungs(for: family)
        if let hovered, let match = rungs.first(where: { $0.id == hovered }) { return match }
        return rungs.first { $0.id == state.selectedTarget.id } ?? rungs.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ladder
            detail
            Divider().overlay(guideAccent.opacity(0.35))
            verdict
            Spacer(minLength: 0)
            tokens
        }
        .padding(12)
        .frame(width: 232)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(guideAccent.opacity(0.09))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(guideAccent.opacity(0.5), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: Ladder

    private var ladder: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Ladder.rungs(for: family)) { rung in
                VStack(spacing: 3) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Ladder.colour(rung.index, family: family))
                            .opacity(rung.selectable ? 1 : 0.3)
                            .frame(height: Ladder.height(rung.index))
                        // The ring is the recommendation. Brightness is capability. Keeping them on
                        // separate channels stops the brightest rung reading as the one to pick.
                        if state.advice?.model.id == rung.id {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.primary, lineWidth: 1.5)
                                .frame(height: Ladder.height(rung.index) + 5)
                        }
                    }
                    .frame(height: 40, alignment: .bottom)

                    Text(rung.label)
                        .font(.system(size: 8, weight: rung.id == state.selectedTarget.id ? .bold : .regular))
                        .foregroundStyle(rung.selectable ? .primary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Rectangle()
                        .fill(rung.id == state.selectedTarget.id ? guideAccent : .clear)
                        .frame(height: 2)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onHover { state.hoveredRung = $0 ? rung.id : nil }
                .onTapGesture {
                    if let t = rung.target { state.selectedTarget = t }
                }
            }
        }
        // A per-rung exit event can be dropped when the pointer crosses two rungs in one move, or
        // jumps rather than travels. onContinuousHover's .ended fires for the ladder as a whole and
        // is the reliable clear, so enter is tracked per rung and exit is tracked once, here.
        .onContinuousHover { phase in
            if case .ended = phase { state.hoveredRung = nil }
        }
    }

    // MARK: Hover detail, fixed height

    private var detail: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let rung = focused {
                Text("\(rung.label)  \(Rubric.value("price", rung.id, fallback: ""))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(guideAccent)
                // One line each, no exceptions. A wrapped line would push this block past its
                // reserved height and collide with the verdict underneath.
                ForEach(Array(Ladder.detail(rung.id).enumerated()), id: \.offset) { _, row in
                    Text(row.job)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if !row.why.isEmpty {
                        Text(row.why)
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.leading, 8)
                    }
                }
            }
        }
        .frame(height: 140, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Verdict

    @ViewBuilder
    private var verdict: some View {
        if let advice = state.advice {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(advice.verdict.badge)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(advice.verdict.tint)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    if let why = advice.signals.first {
                        Text(why)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(advice.model.id == "haiku"
                     ? "\(advice.model.label) · no effort setting"
                     : "\(advice.model.label) · \(advice.effort)")
                    .font(.system(size: 12, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)

                if state.awaitingChoice && !advice.verdict.needsDecision {
                    Button { state.rewriteAnyway() } label: {
                        Text("Translate for \(state.selectedTarget.label)")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                } else if state.awaitingChoice {
                    Button { state.acceptRecommendation() } label: {
                        Text("Use \(advice.model.label)")
                            .font(.system(size: 10, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)

                    Button { state.rewriteAnyway() } label: {
                        Text("Keep \(state.selectedTarget.label)")
                            .font(.system(size: 10))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .controlSize(.small)
                }
            }
        } else {
            Text("Press Translate for a model and effort pick.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: One token line

    private var tokens: some View {
        Text(state.advice == nil
             ? "~\(TokenEstimate.format(state.translationInputTokens)) in"
             : "~\(TokenEstimate.format(state.translationInputTokens)) in · opus/\(state.engineEffort)")
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(.secondary)
    }
}

/// The "why" behind the confidence percent: one ticked or unticked line per criterion. A checklist
/// survives contact with a model that has no dedicated prompting page (Haiku 4.5) far better than a
/// bare percentage does, since the unticked line says exactly what's missing instead of asking
/// the user to trust a number.
struct ConfidenceChecklist: View {
    let criteria: [ConfidenceCriterion]

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(criteria, id: \.label) { criterion in
                HStack(spacing: 4) {
                    Image(systemName: criterion.met ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 9))
                        .foregroundStyle(criterion.met ? Color(red: 0.16, green: 0.55, blue: 0.30) : .secondary)
                    Text(criterion.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .strikethrough(!criterion.met, color: .secondary)
                }
            }
        }
    }
}

/// One of the five harness layers (see reference/rewrite-evals.md) as it applied to the
/// last run. A layer the app does not run per prompt says so rather than showing a tick it did not
/// earn.
struct PhaseStatus: Hashable {
    let name: String
    let detail: String
    let ran: Bool
}

enum Phases {
    static let names = ["Eval classifier", "Schema contracts", "Purpose built tools",
                        "Deterministic workflows", "Failure replay"]

    static var idle: [PhaseStatus] {
        names.map { PhaseStatus(name: $0, detail: "no run yet", ran: false) }
    }

    static func after(_ check: CheckResult?, attempts: Int) -> [PhaseStatus] {
        let judge: String
        if let check {
            if check.notes.contains(where: { $0.hasPrefix("Judge unavailable") }) {
                judge = "code checks, judge unavailable"
            } else if check.notes.contains(where: { $0.hasPrefix("Judge skipped") }) {
                judge = "code checks, judge skipped"
            } else {
                judge = check.judgeArmed ? "code checks and judge" : "code checks, advisory judge"
            }
        } else {
            judge = "checker did not run"
        }
        let ran = check != nil
        return [
            PhaseStatus(name: names[0], detail: judge, ran: ran),
            PhaseStatus(name: names[1], detail: ran ? "one prompt, no wrapper, tag or slot" : "checker did not run", ran: ran),
            PhaseStatus(name: names[2], detail: "no tools on rewrite or judge", ran: true),
            PhaseStatus(name: names[3], detail: "rewrite, check, bounce: \(attempts) of \(check?.maxAttempts ?? attempts)", ran: true),
            PhaseStatus(name: names[4], detail: "offline gate; file misses below", ran: false),
        ]
    }
}

struct PhaseList: View {
    let phases: [PhaseStatus]

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                HStack(spacing: 4) {
                    Image(systemName: phase.ran ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 9))
                        .foregroundStyle(phase.ran ? Color(red: 0.16, green: 0.55, blue: 0.30) : .secondary)
                    Text("\(index + 1). \(phase.name)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(phase.detail)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
    }
}

/// Replaces the old blanket "Primary Anthropic docs" line: only the pages that actually fed the
/// selected target's entry, each a real clickable link to the page itself.
struct SourceLinksRow: View {
    let links: [SourceLink]

    var body: some View {
        // Two columns: six links stacked in one column cost the editors below about 70 points of
        // height, enough to push the whole window past a short screen.
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                  alignment: .leading, spacing: 1) {
            ForEach(links, id: \.url) { link in
                if let url = URL(string: link.url) {
                    Link(link.label, destination: url)
                        .font(.system(size: 9, design: .monospaced))
                }
            }
        }
        .padding(.top, 2)
    }
}

/// The line beside Translate while the guide waits for a choice. When the guide suggests a
/// different model it carries a button that switches to that model and starts the rewrite.
struct ChoiceAlert: View {
    @ObservedObject var state: TranslatorState

    var body: some View {
        if state.awaitingChoice, let advice = state.advice, advice.verdict.needsDecision {
            Text(advice.verdict == .underpowered
                 ? "\(state.selectedTarget.label) is weaker than this task needs. Guide suggests \(advice.model.label)."
                 : "Guide suggests \(advice.model.label).")
                .font(.caption)
                .foregroundStyle(guideAccent)
            Button("Switch to \(advice.model.label)") { state.acceptRecommendation() }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .help("Select \(advice.model.label) and translate for it")
        } else if state.awaitingChoice {
            Text("Check the guide first.")
                .font(.caption)
                .foregroundStyle(guideAccent)
        }
    }
}

struct ContentView: View {
    @StateObject private var state = TranslatorState()

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            GuidePanel(state: state)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Rosetta Prompt").font(.title2).bold()
                    Spacer()
                    Picker("Target", selection: $state.selectedTarget) {
                        ForEach(targets) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .frame(width: 220)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sourced \(state.selectedTarget.sourceDate) · \(state.selectedTarget.confidencePercent)% confidence")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.gray)
                    HStack(alignment: .top, spacing: 24) {
                        ConfidenceChecklist(criteria: state.selectedTarget.confidenceCriteria)
                        PhaseList(phases: state.phases)
                    }
                    SourceLinksRow(links: state.selectedTarget.sourceLinks)
                }

                Text("Messy prompt").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $state.messyPrompt)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 90)
                    .border(Color.gray.opacity(0.3))

                DisclosureGroup("Extra context (optional)") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Anything the prompt leans on that a fresh model can't know: decisions already made, names, file paths.")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)

                        TextEditor(text: $state.extraContext)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 50)
                            .border(Color.gray.opacity(0.3))
                    }
                }

                HStack {
                    Button(state.isRunning ? (state.status.isEmpty ? "Translating..." : state.status) : "Translate") {
                        state.translate()
                    }
                    .disabled(state.isRunning
                              || state.awaitingChoice
                              || state.messyPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)

                    if state.isRunning {
                        ProgressView().controlSize(.small)
                    }
                    ChoiceAlert(state: state)
                    Spacer()
                    if !state.errorText.isEmpty {
                        Text(state.errorText).font(.caption).foregroundStyle(.red).lineLimit(2)
                    }
                }

                HStack {
                    Text("Result").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if state.canReportWrong {
                        Button("This rewrite was wrong") { state.reportingWrong.toggle() }
                            .font(.caption)
                    }
                    Button("Copy") { state.copyResult() }
                        .disabled(state.result.isEmpty)
                        .font(.caption)
                }
                if state.reportingWrong {
                    HStack {
                        TextField("What was wrong with it?", text: $state.wrongReason)
                            .font(.caption)
                            .onSubmit { state.saveWrongCase() }
                        Button("Save case") { state.saveWrongCase() }
                            .font(.caption)
                            .disabled(state.wrongReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                if !state.caseStatus.isEmpty {
                    Text(state.caseStatus)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                if !state.checkSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.checkSummary)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(state.checkPassed ? Color(red: 0.16, green: 0.55, blue: 0.30) : Color.red)
                        ForEach(state.checkLines, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                TextEditor(text: .constant(state.result))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 110)
                    .border(Color.gray.opacity(0.3))
            }
        }
        .padding(16)
        // Pinned to the top: when the window is shorter than the content (a short screen, larger
        // text), SwiftUI centred it and cut off the title and Target picker. Now only the bottom
        // of the result box can run short, and the minimum height fits a 13-inch screen.
        .frame(minWidth: 830, maxWidth: .infinity, minHeight: 560, maxHeight: .infinity, alignment: .top)
    }
}

@main
struct RosettaPromptApp: App {
    var body: some Scene {
        WindowGroup("Rosetta Prompt") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
    }
}
