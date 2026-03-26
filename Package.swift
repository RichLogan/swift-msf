// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-msf",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MSF", targets: ["MSF"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(name: "MSF"),
        .executableTarget(
            name: "msf-gen",
            dependencies: [
                "MSF",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "publish-catalog",
            dependencies: [
                "msf-gen",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "MSFTests", dependencies: ["MSF"]),
    ]
)
