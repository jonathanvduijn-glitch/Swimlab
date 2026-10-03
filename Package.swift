// swift-tools-version: 6.0
// Builds the UI-free part of the app (Core/ and Models/ plus the seed JSON) as a package,
// so the calculation tests run with `swift test` without the Xcode project or a simulator.
// The Xcode app target compiles the same files; this package does not replace it.

import PackageDescription

let package = Package(
    name: "Voedingswijzer",
    platforms: [.iOS(.v18), .macOS(.v15)],
    targets: [
        .target(
            name: "Voedingswijzer",
            path: "Voedingswijzer",
            sources: ["Core", "Models"],
            resources: [.process("Resources/Data")]
        ),
        .testTarget(
            name: "VoedingswijzerTests",
            dependencies: ["Voedingswijzer"],
            path: "VoedingswijzerTests"
        ),
    ]
)
