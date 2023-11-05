// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CoreLMDB",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CoreLMDB",
            targets: ["CoreLMDB"]
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
            name: "CoreLMDB",
            dependencies: ["CLMDB"]
        ),
        .testTarget(
            name: "CoreLMDBTests",
            dependencies: ["CoreLMDB"]
        ),
    ]
)
