// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KollioServer",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KollioServerKit", targets: ["KollioServerKit"]),
        .executable(name: "kollio-server", targets: ["KollioServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.0"),
        .package(path: "../../packages/KollioCore")
    ],
    targets: [
        .target(
            name: "KollioServerKit",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "KollioCore", package: "KollioCore")
            ]
        ),
        .executableTarget(
            name: "KollioServer",
            dependencies: ["KollioServerKit"]
        ),
        .testTarget(
            name: "KollioServerKitTests",
            dependencies: [
                "KollioServerKit",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "KollioCore", package: "KollioCore")
            ]
        )
    ]
)
