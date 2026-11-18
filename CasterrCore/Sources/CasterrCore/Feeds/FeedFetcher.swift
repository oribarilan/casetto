import Foundation

public enum FeedFetchError: Error, Equatable {
    case network(URLError)
    case httpStatus(Int)
}

/// Fetches a feed body with a plain GET.
public struct FeedFetcher: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(_ url: URL) async throws(FeedFetchError) -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw .network(error as? URLError ?? URLError(.unknown))
        }
        guard let http = response as? HTTPURLResponse else { throw .network(URLError(.badServerResponse)) }
        guard (200..<300).contains(http.statusCode) else { throw .httpStatus(http.statusCode) }
        return data
    }
}
