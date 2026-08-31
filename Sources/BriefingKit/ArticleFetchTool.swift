import Foundation
import FoundationModels
import OSLog

@available(macOS 26.0, iOS 26.0, *)
public struct ArticleFetchTool: Tool {

    public init(
        excerptLength: Int = 800,
        urlSession: URLSession = .shared,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) {
        self.excerptLength = excerptLength
        self.urlSession = urlSession
        self.onProgress = onProgress
    }

    private let logger = Logger(subsystem: "com.ai-briefing", category: "ArticleFetchTool")
    private let excerptLength: Int
    private let urlSession: URLSession
    private let onProgress: (@Sendable (String) -> Void)?

    public let name = "fetchArticle"

    public let description = "Download and extract readable text from an article URL."

    @Generable
    public struct Arguments {
        public var url: String
    }

    public struct Output: PromptRepresentable {
        public let content: String

        public var promptRepresentation: Prompt {
            content
        }
    }

    public func call(arguments: Arguments) async throws -> Output {

        logger.info("Fetching article: \(arguments.url, privacy: .public)")
        onProgress?("Fetching article: \(arguments.url)")

        guard let url = URL(string: arguments.url) else {
            logger.warning("Invalid URL: \(arguments.url, privacy: .public)")
            return Output(content: "[Invalid URL]")
        }

        let (data, response) = try await urlSession.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        logger.debug("Article response: HTTP \(statusCode), \(data.count) bytes from \(url.host() ?? "unknown", privacy: .public)")

        guard statusCode == 200 || statusCode == 0 else {
            logger.warning("HTTP \(statusCode) for URL: \(arguments.url, privacy: .public)")
            return Output(content: "[HTTP \(statusCode): fetch failed]")
        }

        guard let html = String(data: data, encoding: .utf8) else {
            logger.warning("Could not decode response as UTF-8 for URL: \(arguments.url, privacy: .public)")
            return Output(content: "[Could not decode article content]")
        }

        let excerpt = HTMLStripper.excerpt(html, maxLength: excerptLength)
        logger.info("Extracted \(excerpt.count) characters from article at \(url.host() ?? "unknown", privacy: .public)")
        return Output(content: excerpt)
    }
}
