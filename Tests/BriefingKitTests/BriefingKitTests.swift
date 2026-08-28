import Foundation
import Testing
@testable import BriefingKit

struct RSSLinkExtractorTests {

    @Test func skipsChannelLinkAndCapsAtThree() {
        let xml = """
        <rss>
          <channel>
            <link>https://news.google.com/</link>
            <item><link>https://example.com/a</link></item>
            <item><link>https://example.com/b</link></item>
            <item><link>https://example.com/c</link></item>
            <item><link>https://example.com/d</link></item>
          </channel>
        </rss>
        """

        let urls = RSSLinkExtractor.urls(from: xml, maxCount: 3)

        #expect(urls == [
            "https://example.com/a",
            "https://example.com/b",
            "https://example.com/c",
        ])
    }

    @Test func returnsEmptyWhenThereAreNoItemLinks() {
        let xml = "<rss><channel><link>https://news.google.com/</link></channel></rss>"
        #expect(RSSLinkExtractor.urls(from: xml).isEmpty)
    }

    @Test func returnsEmptyForNonRSSText() {
        #expect(RSSLinkExtractor.urls(from: "not xml").isEmpty)
    }
}

struct HTMLStripperTests {

    @Test func removesTags() {
        #expect(HTMLStripper.strip("<p>Hello <b>world</b></p>") == "Hello world")
    }

    @Test func leavesPlainTextUnchanged() {
        #expect(HTMLStripper.strip("plain text") == "plain text")
    }

    @Test func truncatesExcerpt() {
        let html = "<p>" + String(repeating: "a", count: 900) + "</p>"
        let excerpt = HTMLStripper.excerpt(html, maxLength: 800)
        #expect(excerpt.count == 800)
        #expect(!excerpt.contains("<"))
    }
}

struct ArticleFetchToolTests {

    @Test func invalidURLReturnsEmptyContent() async throws {
        let output = try await ArticleFetchTool().call(arguments: .init(url: ""))
        #expect(output.content.isEmpty)
    }
}

struct WebSearchToolTests {

    @Test func exposesSearchMetadata() {
        let tool = WebSearchTool()
        #expect(tool.name == "searchWeb")
        #expect(tool.description.contains("article URLs"))
    }

    @Test func outputJoinsURLsForThePrompt() {
        let urls = ["https://a.example", "https://b.example"]
        let output = WebSearchTool.Output(urls: urls)
        #expect(output.urls == urls)
        #expect(String(describing: output.promptRepresentation).contains("https://a.example"))
        #expect(String(describing: output.promptRepresentation).contains("https://b.example"))
    }
}
