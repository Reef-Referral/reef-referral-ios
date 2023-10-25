// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "reef-referral-ios",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ReefReferral",
            targets: ["ReefReferral"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2")
    ],
    targets: [
        .target(
            name: "ReefReferral",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            resources: [
                .copy("README.md")
            ]
        ),
    ]
)
