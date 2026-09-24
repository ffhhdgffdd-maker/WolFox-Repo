// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "NimbleKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "NimbleKit", targets: ["NimbleExtensions","NimbleJSON","NimbleViews"])
    ],
    targets: [
        .target(name: "NimbleExtensions"),
        .target(name: "NimbleJSON", dependencies:["NimbleExtensions"]),
        .target(name: "NimbleViews", dependencies:["NimbleExtensions"])
    ]
)
