// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CommonUtils",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14)
    ],
    products: [
        .library(name: "CommonUtils", targets: ["CommonUtils"])
    ],
    dependencies: [],
    targets: [
        .target(name: "CommonUtils", dependencies: [])
    ]
)
