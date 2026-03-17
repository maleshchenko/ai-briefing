import Foundation
import FoundationModels

@available(macOS 26.0, *)
struct WebSearchTool: Tool {

    @Generable
    struct Arguments {
        var query: String
    }

    struct Output: PromptRepresentable {
        let urls: [String]

        var promptRepresentation: Prompt {
            urls.joined(separator: "\n")
        }
    }

    var name: String { "searchWeb" }

    var description: String {
        "Search recent news and return article URLs."
    }

    func call(arguments: Arguments) async throws -> Output {

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

        let pattern = "<link>(.*?)</link>"
        let regex = try! NSRegularExpression(pattern: pattern)

        let matches = regex.matches(
            in: xml,
            range: NSRange(xml.startIndex..., in: xml)
        )

        var results: [String] = []

        for match in matches.dropFirst() {
            if let range = Range(match.range(at: 1), in: xml) {
                results.append(String(xml[range]))
            }
            if results.count >= 5 { break }
        }

        return Output(urls: results)
    }
}
