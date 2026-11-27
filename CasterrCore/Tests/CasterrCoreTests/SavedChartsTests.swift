import Foundation
import Testing

@testable import CasterrCore

struct SavedChartsTests {
    private let charts = SavedCharts(folder: .temporaryDirectory.appending(path: "charts-\(UUID().uuidString)"))
    private let show = DirectoryShow(
        id: "1", title: "Planet Money", author: "NPR",
        artworkURL: URL(string: "https://example.com/pm.jpg"),
        feedURL: URL(string: "https://feeds.npr.org/510289/podcast.xml")!)

    @Test func savedChartReadsBackPerCountry() {
        charts.save([show], for: "il")
        #expect(charts.shows(for: "il") == [show])
        #expect(charts.shows(for: "us") == nil)
        #expect(charts.size > 0)
        charts.clear()
    }

    @Test func clearForgetsEveryChart() {
        charts.save([show], for: "il")
        charts.save([show], for: "us")
        charts.clear()
        #expect(charts.shows(for: "il") == nil)
        #expect(charts.size == 0)
    }
}
