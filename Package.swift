// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "NodeTool",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "NodeTool", targets: ["NodeTool"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NodeTool",
            dependencies: [])
    ]
)
