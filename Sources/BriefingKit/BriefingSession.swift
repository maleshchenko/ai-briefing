import Foundation
import FoundationModels
import OSLog

@available(macOS 26.0, iOS 26.0, *)
public struct BriefingSession {

    public enum Error: Swift.Error {
        case guardrailViolation
    }

    private static let logger = Logger(subsystem: "com.ai-briefing", category: "BriefingSession")
    private static let maxAttempts = 3

    public static func fetch(topic: String) async throws -> DailyBriefing {

        logger.info("Fetching briefing for topic: \(topic, privacy: .public)")

        let model = SystemLanguageModel.default
        let prompt = """
            Search for recent news about the following topic and fetch the articles. \
            For each article, preserve specific details: names, numbers, dates, quotes, and decisions. \
            Do not generalize or merge articles into vague statements. \
            Each bullet point should reflect a distinct, concrete fact from a specific source.

            Topic: \(topic)
            """

        for attempt in 1...maxAttempts {
            logger.debug("Generation attempt \(attempt)/\(maxAttempts)")
            do {
                let session = LanguageModelSession(
                    model: model,
                    tools: [WebSearchTool(), ArticleFetchTool()]
                )
                let response = try await session.respond(to: prompt, generating: DailyBriefing.self)
                logger.info("Briefing generated successfully on attempt \(attempt)")
                return response.content
            } catch LanguageModelSession.GenerationError.guardrailViolation {
                logger.warning("Guardrail violation on attempt \(attempt)")
                if attempt == maxAttempts {
                    logger.error("All \(maxAttempts) attempts hit guardrail violation — giving up")
                    throw Error.guardrailViolation
                }
            }
        }

        throw Error.guardrailViolation
    }
}
