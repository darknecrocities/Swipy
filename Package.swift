// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Swipy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Swipy", targets: ["Swipy"]),
        .library(name: "SwipyCore", targets: ["SwipyCore"]),
        .executable(name: "SwipyTestRunner", targets: ["SwipyTestRunner"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwipyCore",
            dependencies: [],
            path: "Sources/SwipyCore"
        ),
        .executableTarget(
            name: "Swipy",
            dependencies: ["SwipyCore"],
            path: "Sources/Swipy"
        ),
        .executableTarget(
            name: "SwipyTestRunner",
            dependencies: ["SwipyCore"],
            path: "Tests/SwipyTests"
        )
    ]
)
