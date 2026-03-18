import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
public struct BriefingSession {

    public enum Error: Swift.Error {
        case guardrailViolation
    }

    private static let maxAttempts = 3

    public static func fetch(topic: String) async throws -> DailyBriefing {

        let model = SystemLanguageModel.default
        let prompt = """
            Search for recent news about the following topic and fetch the articles. \
            For each article, preserve specific details: names, numbers, dates, quotes, and decisions. \
            Do not generalize or merge articles into vague statements. \
            Each bullet point should reflect a distinct, concrete fact from a specific source.

            Topic: \(topic)
            """

        for attempt in 1...maxAttempts {
            do {
                let session = LanguageModelSession(
                    model: model,
                    tools: [WebSearchTool(), ArticleFetchTool()]
                )
                let response = try await session.respond(to: prompt, generating: DailyBriefing.self)
                return response.content
            } catch LanguageModelSession.GenerationError.guardrailViolation {
                if attempt == maxAttempts {
                    throw Error.guardrailViolation
                }
            }
        }

        throw Error.guardrailViolation
    }
}
