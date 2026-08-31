import Foundation
import FoundationModels
import OSLog

@available(macOS 26.0, iOS 26.0, *)
public struct BriefingSession {

    public enum Error: Swift.Error {
        case guardrailViolation
        case networkError(Swift.Error)
    }

    private static let logger = Logger(subsystem: "com.ai-briefing", category: "BriefingSession")
    private static let maxAttempts = 3

    /// Default session shared across calls when no custom session is provided.
    private static let defaultURLSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    public static func fetch(
        topic: String,
        articles: Int = 3,
        excerptLength: Int = 800,
        urlSession: URLSession? = nil,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) async throws -> DailyBriefing {

        logger.info("Fetching briefing for topic: \(topic, privacy: .public)")

        let session = urlSession ?? defaultURLSession
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
            onProgress?("Generating briefing (attempt \(attempt)/\(maxAttempts))…")
            do {
                let modelSession = LanguageModelSession(
                    model: model,
                    tools: [
                        WebSearchTool(maxArticles: articles, urlSession: session, onProgress: onProgress),
                        ArticleFetchTool(excerptLength: excerptLength, urlSession: session, onProgress: onProgress),
                    ]
                )
                let response = try await modelSession.respond(to: prompt, generating: DailyBriefing.self)
                logger.info("Briefing generated successfully on attempt \(attempt)")
                return response.content
            } catch LanguageModelSession.GenerationError.guardrailViolation {
                logger.warning("Guardrail violation on attempt \(attempt)")
                if attempt == maxAttempts {
                    logger.error("All \(maxAttempts) attempts hit guardrail violation — giving up")
                    throw Error.guardrailViolation
                }
            } catch let urlError as URLError {
                logger.error("Network error: \(urlError.localizedDescription)")
                throw Error.networkError(urlError)
            }
        }

        throw Error.guardrailViolation
    }
}
