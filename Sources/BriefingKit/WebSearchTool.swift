import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
public struct WebSearchTool: Tool {

    public init() {}

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

        let encoded = arguments.query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""

        let url = URL(string:
            "https://news.google.com/rss/search?q=\(encoded)"
        )!

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let xml = String(data: data, encoding: .utf8) else {
            return Output(urls: [])
        }

        return Output(urls: RSSLinkExtractor.urls(from: xml, maxCount: 3))
    }
}
