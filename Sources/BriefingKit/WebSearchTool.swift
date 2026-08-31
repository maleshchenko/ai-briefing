import Foundation
import FoundationModels
import OSLog

@available(macOS 26.0, iOS 26.0, *)
public struct WebSearchTool: Tool {

    public init(
        maxArticles: Int = 3,
        urlSession: URLSession = .shared,
        onProgress: (@Sendable (String) -> Void)? = nil
    ) {
        self.maxArticles = maxArticles
        self.urlSession = urlSession
        self.onProgress = onProgress
    }

    private let logger = Logger(subsystem: "com.ai-briefing", category: "WebSearchTool")
    private let maxArticles: Int
    private let urlSession: URLSession
    private let onProgress: (@Sendable (String) -> Void)?

    @Generable
    public struct Arguments {
        public var query: String
    }

    public struct Output: PromptRepresentable {
        public let urls: [String]

        public var promptRepresentation: Prompt {
            urls.joined(separator: "\n")
        }
    }

    public var name: String { "searchWeb" }

    public var description: String {
        "Search recent news and return article URLs."
    }

    public func call(arguments: Arguments) async throws -> Output {

        logger.info("Searching for: \(arguments.query, privacy: .public)")
        onProgress?("Searching: \(arguments.query)")

        let encoded = arguments.query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""

        let url = URL(string: "https://news.google.com/rss/search?q=\(encoded)")!

        let (data, response) = try await urlSession.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        logger.debug("RSS feed response: HTTP \(statusCode), \(data.count) bytes")

        guard statusCode == 200 || statusCode == 0 else {
            logger.warning("HTTP \(statusCode) fetching RSS for query: \(arguments.query, privacy: .public)")
            return Output(urls: [])
        }

        guard let xml = String(data: data, encoding: .utf8) else {
            logger.warning("Could not decode RSS response as UTF-8 for query: \(arguments.query, privacy: .public)")
            return Output(urls: [])
        }

        let urls = RSSLinkExtractor.urls(from: xml, maxCount: maxArticles)
        logger.info("Found \(urls.count) article URL(s) for query: \(arguments.query, privacy: .public)")
        return Output(urls: urls)
    }
}
