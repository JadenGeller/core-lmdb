// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftKV",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftKV",
            targets: ["SwiftKV"]
        ),
    ],
    dependencies: [
        .package(
            url:"https://github.com/tannerdsilva/CLMDB.git",
            exact: "0.9.31"
        ),
    ],
    targets: [
        .target(
            name: "SwiftKV",
            dependencies: ["CLMDB"]
        ),
        .testTarget(
            name: "SwiftKVTests",
            dependencies: ["SwiftKV"]
        ),
    ]
)
