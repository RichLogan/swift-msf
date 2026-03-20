// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-msf",
    products: [
        .library(name: "MSF", targets: ["MSF"]),
    ],
    targets: [
        .target(name: "MSF"),
        .testTarget(name: "MSFTests", dependencies: ["MSF"]),
    ]
)
