// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "URLRequestBuilder",
    platforms: [
        .iOS(.v8),
        .macOS(.v10_10),
        .tvOS(.v9),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "URLRequestBuilder",
            targets: ["URLRequestBuilder"]),
    ],
    targets: [
        .target(
            name: "URLRequestBuilder",
            dependencies: []),
        .testTarget(
            name: "URLRequestBuilderTests",
            dependencies: ["URLRequestBuilder"]),
    ]
)
