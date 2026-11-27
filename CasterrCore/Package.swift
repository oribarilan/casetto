// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "CasterrCore",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "CasterrCore", targets: ["CasterrCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit.git", exact: "10.10.2")
    ],
    targets: [
        .target(
            name: "CasterrCore",
            dependencies: ["FeedKit"],
            swiftSettings: [.enableUpcomingFeature("ApproachableConcurrency"), .treatAllWarnings(as: .error)]
        ),
        .testTarget(
            name: "CasterrCoreTests",
            dependencies: ["CasterrCore"],
            resources: [.copy("Fixtures")],
            swiftSettings: [.enableUpcomingFeature("ApproachableConcurrency"), .treatAllWarnings(as: .error)]
        ),
    ]
)
