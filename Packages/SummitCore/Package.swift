// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SummitCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "SummitCore", targets: ["SummitCore"])
    ],
    targets: [
        .target(
            name: "SummitCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SummitCoreTests",
            dependencies: ["SummitCore"],
            resources: [.process("Resources")]
        )
    ]
)
