/// Matches a search against a show you follow: every word must appear somewhere in the title
/// or author, ignoring case and accents, so "pock econ" finds "Pocket Economics". Typos don't match.
public enum ShowSearch {
    public static func matches(_ query: String, title: String, author: String?) -> Bool {
        let words = query.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return false }
        let haystack = [title, author ?? ""].joined(separator: " ")
        return words.allSatisfy { haystack.localizedStandardContains($0) }
    }
}
