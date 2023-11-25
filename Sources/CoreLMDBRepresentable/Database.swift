//import CoreLMDB
//
//extension Database {
//    /// Retrieves the data associated with a given key within a transaction.
//    ///
//    /// - Parameters:
//    ///   - key: The `RawBufferRepresentable` key for which to retrieve the data.
//    ///   - valueType: The `RawBufferRepresentable` type to initialize with the raw data.
//    ///   - transaction: The transaction within which the data retrieval should occur.
//    /// - Returns: An optional `RawBufferRepresentable` value associated with the key if it exists; otherwise, `nil`.
//    /// - Throws: An `LMDBError` if the operation fails.
//    @inlinable @inline(__always)
//    public func get<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(atKey key: Key, as valueType: Value.Type, in transaction: Transaction) throws -> Value? {
//        try key.withUnsafeBytes { key in
//            try get(atKey: key, in: transaction).map(Value.init(buffer:))
//        }
//    }
//
//    /// Stores a key/data pair in the database within a transaction.
//    ///
//    /// - Parameters:
//    ///   - value: The `RawBufferRepresentable` data to store.
//    ///   - key: The `RawBufferRepresentable` key under which to store the data.
//    ///   - overwrite: A Boolean value that determines whether to overwrite an existing value for a key. Defaults to `true`.
//    ///   - transaction: The transaction within which the data storage should occur.
//    /// - Throws: An `LMDBError` if the operation fails.
//    @inlinable @inline(__always)
//    public func put<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(_ value: Value, atKey key: Key, overwrite: Bool = true, in transaction: Transaction) throws {
//        try key.withUnsafeBytes { key in
//            try value.withUnsafeBytes { value in
//                try put(value, atKey: key, overwrite: overwrite, in: transaction)
//            }
//        }
//    }
//
//    /// Deletes all data associated with a given key within a transaction.
//    ///
//    /// - Parameters:
//    ///   - key: The `RawBufferRepresentable` key for which to delete the data.
//    ///   - transaction: The transaction within which the deletion should occur.
//    /// - Throws: An `LMDBError` if the operation fails.
//    @inlinable @inline(__always)
//    public func delete<Key: RawBufferRepresentable>(atKey key: Key, in transaction: Transaction) throws {
//        try key.withUnsafeBytes { key in
//            try delete(atKey: key, value: nil, in: transaction)
//        }
//    }
//    
//    /// Deletes the data associated with a given key within a transaction.
//    ///
//    /// - Parameters:
//    ///   - key: The `RawBufferRepresentable` key for which to delete the data.
//    ///   - value: The `RawBufferRepresentable` value to delete if the database supports sorted duplicates.
//    ///   - transaction: The transaction within which the deletion should occur.
//    /// - Throws: An `LMDBError` if the operation fails.
//    @inlinable @inline(__always)
//    public func delete<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(atKey key: Key, value: Value, in transaction: Transaction) throws {
//        try key.withUnsafeBytes { key in
//            try value.withUnsafeBytes { value in
//                try delete(atKey: key, value: value, in: transaction)
//            }
//        }
//    }
//}
//
//extension Database {
//    public func keyOrdering<Key: RawBufferRepresentable>(of lhs: Key, _ rhs: Key, in transaction: Transaction) throws -> Ordering {
//        try lhs.withUnsafeBytes { lhs in
//            try rhs.withUnsafeBytes { rhs in
//                keyOrdering(of: lhs, rhs, in: transaction)
//            }
//        }
//    }
//    public func duplicateOrdering<Value: RawBufferRepresentable>(of lhs: Value, _ rhs: Value, in transaction: Transaction) throws -> Ordering {
//        try lhs.withUnsafeBytes { lhs in
//            try rhs.withUnsafeBytes { rhs in
//                duplicateOrdering(of: lhs, rhs, in: transaction)
//            }
//        }
//    }
//}
