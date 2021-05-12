// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "SwiftBert",
    platforms: [
        .macOS(.v10_15), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)
    ],
    products: [
        .library(name: "SwiftBert", targets: ["SwiftBert"]) // product name
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1") // big int
    ],
    targets: [
        .target(
            name: "SwiftBert",
            dependencies: [
                .product(name: "BigInt", package: "BigInt")
            ],
            path: "Sources",
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
        ]),
        .testTarget(name: "SwiftBertTests", dependencies: ["SwiftBert"], path: "Tests")
    ]
)
