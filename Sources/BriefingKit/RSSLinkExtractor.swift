import Foundation

enum RSSLinkExtractor {

    static func urls(from xml: String, maxCount: Int = 3) -> [String] {
        let pattern = "<link>(.*?)</link>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let matches = regex.matches(
            in: xml,
            range: NSRange(xml.startIndex..., in: xml)
        )

        var results: [String] = []

        for match in matches.dropFirst() {
            if let range = Range(match.range(at: 1), in: xml) {
                results.append(String(xml[range]))
            }
            if results.count >= maxCount { break }
        }

        return results
    }
}
