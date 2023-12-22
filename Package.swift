// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "core-lmdb",
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
            name: "CoreLMDBCells",
            targets: ["CoreLMDBCells"]
        ),
        .library(
            name: "CoreLMDBCoders",
            targets: ["CoreLMDBCoders"]
        ),
        .library(
            name: "CoreLMDBCollections",
            targets: ["CoreLMDBCollections"]
        ),
    ],
    dependencies: [
        .package(
            // FIXME: I'd like to depend on the Apple fork, but it doesn't have any tagged releases.
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
            name: "CoreLMDBCells",
            dependencies: ["CoreLMDB"]
        ),
        .target(
            name: "CoreLMDBCoders",
            dependencies: ["CoreLMDB"]
        ),
        .target(
            name: "CoreLMDBCollections",
            dependencies: ["CoreLMDB"]
        ),
        .testTarget(
            name: "CoreLMDBTests",
            dependencies: ["CoreLMDB", "CoreLMDBCoders"]
        ),
        .testTarget(
            name: "CoreLMDBCollectionsTests",
            dependencies: ["CoreLMDBCollections", "CoreLMDBCoders"]
        ),
    ]
)
