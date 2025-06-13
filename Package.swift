// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bundle-analyzer",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/tuist/Rosalind.git", from: "0.5.38")
    ],
    targets: [
        .executableTarget(
            name: "bundle-analyzer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Rosalind", package: "rosalind")
            ]
        ),
    ]
)
