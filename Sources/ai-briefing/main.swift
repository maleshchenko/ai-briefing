import Foundation
import OSLog
import BriefingKit

private let logger = Logger(subsystem: "com.ai-briefing", category: "main")

if #available(macOS 26.0, *) {

    let topic = CommandLine.arguments.dropFirst().joined(separator: " ")

    if topic.isEmpty {
        print("Usage: ai-briefing \"topic\"")
        exit(0)
    }

    do {
        let briefing = try await BriefingSession.fetch(topic: topic)
        print("Key Developments:")
        briefing.keyDevelopments.forEach { print("  - \($0)") }
        print("\nImportant Signals:")
        briefing.importantSignals.forEach { print("  - \($0)") }
        print("\nRisks:")
        briefing.risks.forEach { print("  - \($0)") }
        print("\nThings to Watch:")
        briefing.thingsToWatch.forEach { print("  - \($0)") }
    } catch BriefingSession.Error.guardrailViolation {
        let msg = "The model declined to generate a response after 3 attempts. The topic or retrieved news content may have triggered content filters."
        logger.error("\(msg)")
        print(msg)
    } catch {
        logger.error("Error: \(error)")
        print("Error:", error)
    }

} else {
    print("Apple Foundation Models require macOS 26+")
}
