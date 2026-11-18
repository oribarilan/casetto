import Foundation

public struct OPMLFeed: Equatable, Sendable {
    public var url: URL
    public var title: String?
}

public struct OPMLInvalidEntry: Equatable, Sendable {
    public enum Reason: Equatable, Sendable {
        case missingURL
        case invalidURL(String)
    }

    public var title: String?
    public var reason: Reason
}

public struct OPMLImport: Equatable, Sendable {
    public var feeds: [OPMLFeed] = []
    public var invalidEntries: [OPMLInvalidEntry] = []
}

public enum OPMLError: Error, Equatable {
    /// The XML does not parse or its root element is not `opml`.
    case notOPML
}

public enum OPMLParser {
    public static func parse(_ data: Data) throws(OPMLError) -> OPMLImport {
        let parser = XMLParser(data: data)
        let delegate = Delegate()
        parser.delegate = delegate
        guard parser.parse(), delegate.sawOPMLRoot else { throw .notOPML }
        return delegate.result
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var sawOPMLRoot = false
        var result = OPMLImport()
        /// An outline with no `xmlUrl`. It is a folder if another outline starts before it ends.
        private var pendingNoURL: String??

        func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                    qualifiedName: String?, attributes: [String: String]) {
            if !sawOPMLRoot {
                sawOPMLRoot = name == "opml"
                if !sawOPMLRoot { parser.abortParsing() }
                return
            }
            guard name == "outline" else { return }

            pendingNoURL = nil
            let title = attributes["text"] ?? attributes["title"]
            guard let urlString = attributes["xmlUrl"] else {
                pendingNoURL = .some(title)
                return
            }
            if let url = URL(string: urlString), ShowKey(feedURL: url) != nil {
                result.feeds.append(OPMLFeed(url: url, title: title))
            } else {
                result.invalidEntries.append(OPMLInvalidEntry(title: title, reason: .invalidURL(urlString)))
            }
        }

        func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                    qualifiedName: String?) {
            guard name == "outline", let title = pendingNoURL else { return }
            result.invalidEntries.append(OPMLInvalidEntry(title: title, reason: .missingURL))
            pendingNoURL = nil
        }
    }
}
