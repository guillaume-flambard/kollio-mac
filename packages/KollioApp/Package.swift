// swift-tools-version: 6.0
import Foundation
import PackageDescription

// `Evaluations.framework` is a Developer framework: it sits beside the SDK
// rather than inside it, so SwiftPM cannot find it and it has to be named.
// `scripts/evaluate-apple-model.sh` derives the path from `xcode-select -p` and
// exports KOLLIO_DEVELOPER_FRAMEWORKS.
//
// Only the evaluation test target carries the flag. The library target next to
// it, which is where the structural gate lives, needs no framework at all and
// therefore runs in ordinary CI on any machine.
let developerFrameworks = ProcessInfo.processInfo.environment["KOLLIO_DEVELOPER_FRAMEWORKS"]
    ?? "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks"

let package = Package(
    name: "KollioApp",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Kollio", targets: ["KollioApp"])
    ],
    dependencies: [
        .package(path: "../KollioCore"),
        .package(path: "../../services/KollioServer"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.0")
    ],
    targets: [
        // The measured contract, with no model and no framework in it. This is
        // the part of the evaluation that ordinary CI can prove.
        .target(
            name: "KollioEvaluationKit",
            dependencies: [.product(name: "KollioCore", package: "KollioCore")]
        ),
        .executableTarget(
            name: "KollioApp",
            dependencies: [.product(name: "KollioCore", package: "KollioCore")],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "KollioAppTests",
            dependencies: [
                "KollioApp",
                .product(name: "KollioCore", package: "KollioCore"),
                .product(name: "KollioServerKit", package: "KollioServer"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "XCTVapor", package: "vapor"),
                "KollioEvaluationKit"
            ]
        )
    ]
)
