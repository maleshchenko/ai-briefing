import Foundation
import FoundationModels

if #available(macOS 26.0, *) {

    let topic = CommandLine.arguments.dropFirst().joined(separator: " ")

    if topic.isEmpty {
        print("Usage: ai-briefing \"topic\"")
        exit(0)
    }

    do {
        let model = SystemLanguageModel.default
        let session = LanguageModelSession(
            model: model,
            tools: [WebSearchTool()]
        )
        let prompt = "Summarize the latest news and key developments about the following topic:\n\n\(topic)"
        let response = try await session.respond(to: prompt)
        print(response.content)
    } catch {
        print("Error:", error)
    }

} else {
    print("Apple Foundation Models require macOS 26+")
}
