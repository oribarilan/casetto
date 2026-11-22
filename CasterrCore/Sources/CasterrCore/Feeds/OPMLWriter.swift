import Foundation

/// Writes subscriptions as an OPML 2.0 file that other podcast apps can import.
public enum OPMLWriter {
    public static func write(_ feeds: [(title: String, url: URL)]) -> Data {
        let outlines = feeds.map { feed in
            let title = escape(feed.title)
            return "    <outline type=\"rss\" text=\"\(title)\" title=\"\(title)\" xmlUrl=\"\(escape(feed.url.absoluteString))\"/>"
        }
        let lines = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<opml version=\"2.0\">",
            "  <head><title>Casterr Shows</title></head>",
            "  <body>",
        ] + outlines + ["  </body>", "</opml>", ""]
        return Data(lines.joined(separator: "\n").utf8)
    }

    private static func escape(_ text: String) -> String {
        text.replacing("&", with: "&amp;").replacing("<", with: "&lt;").replacing(">", with: "&gt;")
            .replacing("\"", with: "&quot;").replacing("'", with: "&apos;")
    }
}
