import Foundation
import Testing
@testable import CasterrCore

/// Answers by URL path: "/200" returns a body, "/404" returns that status, anything else fails offline.
private final class StubProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        switch url.path {
        case "/200", "/404":
            let status = Int(url.path.dropFirst())!
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("feed".utf8))
            client?.urlProtocolDidFinishLoading(self)
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        }
    }
}

struct FeedFetcherTests {
    private let fetcher: FeedFetcher = {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        return FeedFetcher(session: URLSession(configuration: config))
    }()

    @Test func returnsBodyOn200() async throws {
        let data = try await fetcher.fetch(URL(string: "https://example.com/200")!)
        #expect(data == Data("feed".utf8))
    }

    @Test func throwsStatusOn404() async {
        await #expect(throws: FeedFetchError.httpStatus(404)) {
            try await fetcher.fetch(URL(string: "https://example.com/404")!)
        }
    }

    @Test func throwsNetworkErrorWhenOffline() async {
        let error = await #expect(throws: FeedFetchError.self) {
            try await fetcher.fetch(URL(string: "https://example.com/offline")!)
        }
        guard case .network(let urlError) = error else {
            Issue.record("expected a network error, got \(String(describing: error))")
            return
        }
        #expect(urlError.code == .notConnectedToInternet)
    }
}
