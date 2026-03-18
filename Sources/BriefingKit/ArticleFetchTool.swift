import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
public struct ArticleFetchTool: Tool {

    public init() {}

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

        guard let url = URL(string: arguments.url) else {
            return Output(content: "")
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let html = String(data: data, encoding: .utf8) else {
            return Output(content: "")
        }

        return Output(content: String(stripHTML(html).prefix(800)))
    }

    private func stripHTML(_ html: String) -> String {

        var text = html

        while let start = text.range(of: "<"),
              let end = text.range(of: ">", range: start.lowerBound..<text.endIndex) {

            text.removeSubrange(start.lowerBound...end.lowerBound)
        }

        return text
    }
}
