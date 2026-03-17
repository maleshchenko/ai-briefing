import Foundation
import FoundationModels

if #available(macOS 26.0, *) {

    let topic = CommandLine.arguments.dropFirst().joined(separator: " ")

    if topic.isEmpty {
        print("Usage: ai-briefing \"topic\"")
        exit(0)
    }

    let model = SystemLanguageModel.default
    let prompt = "Summarize the latest news and key developments about the following topic:\n\n\(topic)"
    var guardrailFailed = false

    for attempt in 1...3 {
        do {
            let session = LanguageModelSession(
                model: model,
                tools: [WebSearchTool()]
            )
            let response = try await session.respond(to: prompt)
            print(response.content)
            guardrailFailed = false
            break
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            guardrailFailed = true
            if attempt < 3 {
                print("Retrying... (\(attempt)/3)")
            }
        } catch {
            print("Error:", error)
            break
        }
    }

    if guardrailFailed {
        print("The model declined to generate a response after 3 attempts. The topic or retrieved news content may have triggered content filters.")
    }

} else {
    print("Apple Foundation Models require macOS 26+")
}
