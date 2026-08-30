# ai-briefing

Generates a structured news briefing on a topic using Apple Intelligence. Inference runs on-device via [FoundationModels](https://developer.apple.com/documentation/foundationmodels). Article URLs and HTML are fetched over the network; the model itself is not a remote API.

The package ships two products:

- **`ai-briefing`** — command-line tool
- **`BriefingKit`** — Swift library for macOS and iOS apps

## Requirements

- macOS 26.0 or iOS 26.0
- Apple Intelligence enabled on the device
- Swift 6.2 or later

## CLI

```
swift run ai-briefing "<topic>"
```

Example:

```
swift run ai-briefing "AI industry"
```

Output is four sections: key developments, important signals, risks, and things to watch.

## Example output

<img width="848" height="485" alt="Screenshot of a CLI briefing" src="https://github.com/user-attachments/assets/ca195718-e989-443b-b52b-69c4b57c887a" />

## Library (iOS / macOS)

Add the package in Xcode (File → Add Package Dependencies) and link **BriefingKit**.

```swift
import BriefingKit

let briefing = try await BriefingSession.fetch(topic: "AI industry")
// briefing.keyDevelopments, .importantSignals, .risks, .thingsToWatch
```

`BriefingSession.fetch` retries up to three times if Apple’s content filters reject a generation.

## Tests

```
swift test
```

Tests cover RSS parsing and HTML stripping. They do not invoke Apple Intelligence.

## Limits

- News search uses Google News RSS. Fetching article text depends on each site’s HTML.
- Apple’s on-device guardrails can refuse a topic or retrieved content (`BriefingSession.Error.guardrailViolation`).
- Article excerpts are truncated so the session stays within the model’s context window.

## License

MIT. See [LICENSE](LICENSE).
