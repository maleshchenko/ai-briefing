import Foundation
import FoundationModels

@available(macOS 26.0, *)
struct ArticleFetchTool: Tool {

    let name = "fetchArticle"

    let description = "Download and extract readable text from an article URL."

    @Generable
    struct Arguments {
        var url: String
    }

    struct Output: PromptRepresentable {
        let content: String

        var promptRepresentation: Prompt {
            content
        }
    }

    func call(arguments: Arguments) async throws -> Output {

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
