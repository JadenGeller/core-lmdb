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
        .library(
            name: "CoreLMDBRepresentable",
            targets: ["CoreLMDBRepresentable"]
        ),
        .library(
            name: "CoreLMDBCollections",
            targets: ["CoreLMDBCollections"]
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
        .target(
            name: "CoreLMDBRepresentable",
            dependencies: ["CoreLMDB"]
        ),
        .target(
            name: "CoreLMDBCollections",
            dependencies: ["CoreLMDB", "CoreLMDBRepresentable"]
        ),
        .testTarget(
            name: "CoreLMDBTests",
            dependencies: ["CoreLMDB", "CoreLMDBRepresentable"]
        ),
        .testTarget(
            name: "CoreLMDBCollectionsTests",
            dependencies: ["CoreLMDBCollections"]
        ),
    ]
)
