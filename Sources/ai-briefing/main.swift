import Foundation
import OSLog
import BriefingKit

private let logger = Logger(subsystem: "com.ai-briefing", category: "main")

private func printStderr(_ message: String) {
    fputs(message + "\n", stderr)
}

// MARK: - Argument parsing

private struct Options {
    var topic: String = ""
    var outputJSON: Bool = false
    var outputPath: String? = nil
    var articles: Int = 3
    var excerptLength: Int = 800
}

private func parseArguments() -> Options {
    var opts = Options()
    let args = Array(CommandLine.arguments.dropFirst())
    var topicWords: [String] = []
    var i = 0
    while i < args.count {
        switch args[i] {
        case "--json":
            opts.outputJSON = true
        case "--output":
            i += 1
            if i < args.count { opts.outputPath = args[i] }
        case "--articles":
            i += 1
            if i < args.count, let n = Int(args[i]), n > 0 { opts.articles = n }
        case "--excerpt-length":
            i += 1
            if i < args.count, let n = Int(args[i]), n > 0 { opts.excerptLength = n }
        default:
            topicWords.append(args[i])
        }
        i += 1
    }
    opts.topic = topicWords.joined(separator: " ")
    return opts
}

// MARK: - Output formatting

@available(macOS 26.0, *)
private func markdownOutput(for briefing: DailyBriefing, topic: String) -> String {
    var lines = ["# AI Briefing: \(topic)", ""]
    func section(_ title: String, _ items: [String]) {
        lines += ["## \(title)"]
        lines += items.map { "- \($0)" }
        lines += [""]
    }
    section("Key Developments", briefing.keyDevelopments)
    section("Important Signals", briefing.importantSignals)
    section("Risks", briefing.risks)
    section("Things to Watch", briefing.thingsToWatch)
    return lines.joined(separator: "\n")
}

@available(macOS 26.0, *)
private func jsonOutput(for briefing: DailyBriefing) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(briefing)
    return String(data: data, encoding: .utf8) ?? "{}"
}

// MARK: - Entry point

if #available(macOS 26.0, *) {

    let opts = parseArguments()

    if opts.topic.isEmpty {
        print("""
            Usage: ai-briefing [options] \"topic\"

            Options:
              --json                   Output as JSON instead of plain text
              --output <path>          Write output to a file (Markdown or JSON)
              --articles <n>           Number of articles to fetch (default: 3)
              --excerpt-length <n>     Characters to extract per article (default: 800)
            """)
        exit(0)
    }

    logger.info("Starting briefing for topic: \(opts.topic, privacy: .public)")

    do {
        let briefing = try await BriefingSession.fetch(
            topic: opts.topic,
            articles: opts.articles,
            excerptLength: opts.excerptLength,
            onProgress: { message in
                printStderr("  ▸ \(message)")
            }
        )

        logger.info("Briefing complete — \(briefing.keyDevelopments.count) developments, \(briefing.risks.count) risks")

        if let path = opts.outputPath {
            let output = opts.outputJSON
                ? try jsonOutput(for: briefing)
                : markdownOutput(for: briefing, topic: opts.topic)
            try output.write(toFile: path, atomically: true, encoding: .utf8)
            print("Briefing saved to \(path)")
            logger.info("Briefing written to \(path, privacy: .public)")
        } else if opts.outputJSON {
            print(try jsonOutput(for: briefing))
        } else {
            print("Key Developments:")
            briefing.keyDevelopments.forEach { print("  - \($0)") }
            print("\nImportant Signals:")
            briefing.importantSignals.forEach { print("  - \($0)") }
            print("\nRisks:")
            briefing.risks.forEach { print("  - \($0)") }
            print("\nThings to Watch:")
            briefing.thingsToWatch.forEach { print("  - \($0)") }
        }

    } catch BriefingSession.Error.guardrailViolation {
        let msg = "The model declined to generate a response after 3 attempts. The topic or retrieved news content may have triggered content filters."
        logger.error("\(msg)")
        print(msg)
    } catch BriefingSession.Error.networkError(let underlying) {
        let msg = "Network error: \(underlying.localizedDescription)"
        logger.error("\(msg)")
        print(msg)
    } catch {
        logger.error("Error: \(error)")
        print("Error:", error)
    }

} else {
    print("Apple Foundation Models require macOS 26+")
}
