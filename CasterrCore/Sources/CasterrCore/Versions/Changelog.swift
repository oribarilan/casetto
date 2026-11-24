import Foundation

/// The app's changelog: "## 0.3" headings, each followed by "- " lines in the listener's words, newest first.
public struct Changelog: Equatable, Sendable {
    public struct Release: Equatable, Sendable {
        public var version: String
        public var lines: [String]
    }

    public var releases: [Release]

    public init(_ text: String) {
        var releases: [Release] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = line.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                releases.append(Release(version: String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces), lines: []))
            } else if line.hasPrefix("- "), !releases.isEmpty {
                releases[releases.count - 1].lines.append(String(line.dropFirst(2)))
            }
        }
        self.releases = releases
    }

    /// The releases newer than `version`, newest first.
    public func releases(after version: String) -> [Release] {
        releases.filter { Self.isNewer($0.version, than: version) }
    }

    /// Compares numbers part by part, so 0.10 is newer than 0.9 and 0.3.1 newer than 0.3.
    public static func isNewer(_ version: String, than other: String) -> Bool {
        let parts = { (text: String) in text.split(separator: ".").map { Int($0) ?? 0 } }
        let (a, b) = (parts(version), parts(other))
        for index in 0..<max(a.count, b.count) {
            let (x, y) = (index < a.count ? a[index] : 0, index < b.count ? b[index] : 0)
            if x != y { return x > y }
        }
        return false
    }
}
