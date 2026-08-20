// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Loopback",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Loopback", targets: ["Loopback"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Loopback",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LoopbackTests",
            dependencies: ["Loopback"]
        ),
    ]
)