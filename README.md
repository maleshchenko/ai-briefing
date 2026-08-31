# ai-briefing

[![CI](https://github.com/mykolaaleshchenko/ai-briefing/actions/workflows/ci.yml/badge.svg)](https://github.com/mykolaaleshchenko/ai-briefing/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmykolaaleshchenko%2Fai-briefing%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mykolaaleshchenko/ai-briefing)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmykolaaleshchenko%2Fai-briefing%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mykolaaleshchenko/ai-briefing)

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
swift run ai-briefing [options] "<topic>"
```

| Option | Default | Description |
|---|---|---|
| `--articles <n>` | `3` | Number of articles to fetch per search |
| `--excerpt-length <n>` | `800` | Characters to extract per article |
| `--json` | — | Output as JSON instead of Markdown |
| `--output <path>` | — | Write output to a file |

### Examples

```bash
# Basic usage
swift run ai-briefing "AI industry"

# Fetch more articles, save as JSON
swift run ai-briefing --articles 5 --json --output briefing.json "Apple WWDC 2025"

# Pipe JSON to jq
swift run ai-briefing --json "climate tech" | jq '.keyDevelopments'
```

Progress is printed to stderr so stdout stays clean for piping and redirection.

## Example output

<img width="848" height="485" alt="Screenshot of a CLI briefing" src="https://github.com/user-attachments/assets/ca195718-e989-443b-b52b-69c4b57c887a" />

## Library (iOS / macOS)

Add the package in Xcode (File → Add Package Dependencies) and link **BriefingKit**.

```swift
import BriefingKit

let briefing = try await BriefingSession.fetch(topic: "AI industry")
// briefing.keyDevelopments, .importantSignals, .risks, .thingsToWatch
```

All parameters are available in the library too:

```swift
let briefing = try await BriefingSession.fetch(
    topic: "climate tech",
    articles: 5,
    excerptLength: 1200,
    onProgress: { message in print(message) }
)
```

`BriefingSession.fetch` retries up to three times if Apple's content filters reject a generation.

## Tests

```
swift test
```

Tests cover RSS parsing and HTML stripping. They do not invoke Apple Intelligence.

## Limits

- News search uses Google News RSS. Fetching article text depends on each site's HTML.
- Apple's on-device guardrails can refuse a topic or retrieved content (`BriefingSession.Error.guardrailViolation`).
- Article excerpts are truncated so the session stays within the model's context window.
- Network requests time out after 10 seconds per request.

## License

MIT. See [LICENSE](LICENSE).
