// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GrowCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "GrowCore",
            targets: ["GrowCore", "GrowCoreCPP"]
        ),
        .library(
            name: "GrowCoreCPP",
            targets: ["GrowCoreCPP"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GrowCoreCPP",
            path: "Sources/GrowCoreCPP",
            publicHeadersPath: "include"
        ),
        .target(
            name: "GrowCore",
            dependencies: ["GrowCoreCPP"],
            path: "Sources/GrowCore",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "GrowCoreTests",
            dependencies: ["GrowCore", "GrowCoreCPP"],
            path: "Tests/GrowCoreTests"
        ),
    ]
)
