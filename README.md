# CoreLMDB

CoreLMDB is a Swift wrapper for the Lightning Memory-Mapped Database (LMDB). It provides a minimal, yet powerful interface to LMDB, a high-performance, Btree-based database management library.

## Usage

Here's a basic example of how to use CoreLMDB:

```swift
import CoreLMDB

let env = try Environment(path: path)
let db = try env.read { try Database.open(in: $0) }
var (key, value) = ("key", "value")
try env.write {
    try db.withWriter(for: $0) { db in
        try withUnsafeBytes(of: &key) { key in
            try withUnsafeBytes(of: &value) { value in
                try db.updateValue(value, forKey: key)
            }
            XCTAssertEqual(value, try db[key]!.load(as: String.self))
        }
    }
}
```

CoreLMDB is a powerful tool that provides a simple and safe interface to LMDB, making it easier to leverage the power of LMDB in your Swift applications.

## Installation

CoreLMDB is available as a Swift Package. You can add it to your project by adding the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/jadengeller/CoreLMDB.git", branch: "main")
]
```

## About LMDB

LMDB is modeled loosely on the BerkeleyDB API, but much simplified. The entire database is exposed in a memory map, and all data fetches return data directly from the mapped memory, eliminating the need for malloc's or memcpy's during data fetches. This makes LMDB extremely high performance and memory-efficient.

LMDB is fully transactional with full ACID semantics, and when the memory map is read-only, the database integrity cannot be corrupted by stray pointer writes from application code. It supports concurrent read/write access from multiple processes and threads. Data pages use a copy-on-write strategy, providing resistance to corruption and eliminating the need for any special recovery procedures after a system crash.

Unlike other database mechanisms which require periodic checkpointing or compaction, LMDB requires no maintenance during operation. It tracks free pages within the database and re-uses them for new write operations, preventing unbounded growth in normal use.

## Why CoreLMDB?

CoreLMDB is a Swift wrapper for LMDB that emphasizes safety and simplicity. It leverages Swift's type system and noncopyable (move-only) types to provide a safer, more Swift-like interface to LMDB. This ensures that database transactions are managed correctly and helps prevent common errors.

CoreLMDB also ensures that your read and write operations are always performed within the correct type of transaction, making your database code easier to understand. It uses Swift types like `UnsafeRawBufferPointer` for a more Swift-friendly API, but it's worth noting that CoreLMDB is a low-level interface and does not handle serialization/deserialization of these types for you.

While CoreLMDB does not expose every single feature of LMDB, it provides what's needed for most use cases. It's a work-in-progress, and contributions are welcome!
