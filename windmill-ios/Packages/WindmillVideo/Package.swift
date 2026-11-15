// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WindmillVideo",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "WindmillVideo", targets: ["WindmillVideo"]),
        .library(name: "WindmillCapture", targets: ["WindmillCapture"]),
    ],
    targets: [
        .target(name: "WindmillVideo"),
        .target(name: "WindmillCapture", dependencies: ["WindmillVideo"]),
        .testTarget(name: "WindmillVideoTests", dependencies: ["WindmillVideo"]),
    ],
    swiftLanguageModes: [.v6]
)
