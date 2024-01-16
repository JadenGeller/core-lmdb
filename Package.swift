// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "core-lmdb",
    platforms: [
        .iOS(.v15),
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
            url: "https://github.com/JadenGeller/swift-lmdb",
            exact: "0.1.2"
        ),
    ],
    targets: [
        .target(
            name: "CoreLMDB",
            dependencies: [.product(name: "CLMDB", package: "swift-lmdb")]
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
