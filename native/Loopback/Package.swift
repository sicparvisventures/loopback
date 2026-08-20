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
            // Sources live in ./Loopback (Xcode-style layout), not ./Sources/Loopback.
            path: "Loopback",
            // Info.plist and entitlements are placed into the .app bundle by
            // scripts/build-app.sh, so they must not be processed as SwiftPM resources.
            exclude: ["Resources"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
