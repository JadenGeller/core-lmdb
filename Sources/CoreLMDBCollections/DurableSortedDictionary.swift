import CoreLMDB
import CoreLMDBRepresentable

// TODO: Is there any way this could be copy-on-write? It would need to reference the environment
public struct DurableSortedDictionary<Key: RawBufferRepresentable, Value: RawBufferRepresentable> {
    internal var database: Database
    internal var transaction: Transaction
    
    public init(for database: Database, in transaction: Transaction) {
        self.database = database
        self.transaction = transaction
    }
}

extension DurableSortedDictionary {
    public subscript(key: Key) -> Value? {
        get {
            try! database.get(atKey: key, as: Value.self, in: transaction)
        }
        set {
            if let newValue {
                try! database.put(newValue, atKey: key, overwrite: true, in: transaction)
            } else {
                try! transaction.withCursor(for: database) { cursor in
                    if try cursor.move(.exactly, toKey: key) != nil {
                        try cursor.delete()
                    }
                }
            }
        }
    }
    
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            self[key] ?? defaultValue()
        }
        set {
            self[key] = newValue
        }
    }
}

extension DurableSortedDictionary: BidirectionalCollection {
    public typealias Index = DatabaseIndex
    public typealias Element = (key: Key, value: Value)

    public var startIndex: Index {
        let index = DatabaseIndex(for: database, in: transaction)
        assert(try! index.move(to: .first) != nil)
        return index
    }
    
    public var endIndex: Index {
        let index = DatabaseIndex(for: database, in: transaction)
        index.moveToEnd()
        return index
    }

    public func index(forKey key: Key) -> Index? {
        let index = DatabaseIndex(for: database, in: transaction)
        guard try! index.move(.exactly, toKey: key) != nil else { return nil }
        return index
    }
    
    public subscript(index: Index) -> Element {
        guard !index.isEnd else { index.preconditionFailure() }
        let item = index.item
        return try! (item.key(as: Key.self), item.value(as: Value.self))
    }
    
    public func formIndex(after i: inout Index) {
        try! i.move(to: .next)
    }
    
    public func formIndex(before i: inout Index) {
        try! i.move(to: .previous)
    }
    
    public func index(after i: Index) -> Index {
        var newIndex = Index(for: database, in: transaction)
        try! newIndex.cursor.move(.exactly, toKey: i.item.key)
        formIndex(after: &newIndex)
        return newIndex
    }
    
    public func index(before i: Index) -> Index {
        var newIndex = Index(for: database, in: transaction)
        try! newIndex.cursor.move(.exactly, toKey: i.item.key)
        formIndex(before: &newIndex)
        return newIndex
    }
}

// TODO: Implement `keys` and `values`

extension DurableSortedDictionary {
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        try! transaction.withCursor(for: database) { cursor in
            defer { try! cursor.put(key: key, value: value) }
            return try! cursor.move(.exactly, toKey: key)?.value(as: Value.self)
        }
    }

    public mutating func merge<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Element == (Key, Value) {
        for (key, newValue) in other {
            if let existingValue = self[key] {
                self[key] = try combine(existingValue, newValue)
            } else {
                self[key] = newValue
            }
        }
    }
}

extension DurableSortedDictionary {
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        defer { self[key] = nil }
        return self[key]
    }
    
    @discardableResult
    public mutating func remove(at index: Index) -> Element {
        defer { try! index.cursor.delete() }
        return self[index]
    }

    public mutating func removeAll() {
        try! database.drop(close: false, in: transaction)
    }
}

extension Transaction {
    /// Executes a block of code with a cursor, closing the cursor once the block returns.
    ///
    /// - Parameters:
    ///   - database: The database for which to create the cursor.
    ///   - block: A closure that performs the work with the cursor. The value it returns is returned by the function.
    /// - Throws: An `LMDBError` if the cursor cannot be created, or any error thrown by the `block`.
    /// - Returns: The value returned by the `block`.
    @inlinable
    public func withDurableSortedDictionary<Key: RawBufferRepresentable, Value: RawBufferRepresentable, Result>(
        as type: (Key.Type, Value.Type),
        for database: Database,
        _ block: (inout DurableSortedDictionary<Key, Value>) throws -> Result
    ) throws -> Result {
        var dict = DurableSortedDictionary<Key, Value>(for: database, in: self)
        return try block(&dict)
    }
}

// each copy has its own read transaction

//// MARK: Accessors
//
//extension Database {
//    /// Retrieves the data associated with a given key within a transaction.
//    ///
//    /// - Parameters:
//    ///   - key: The key for which to retrieve the data, passed as `UnsafeRawBufferPointer`.
//    ///   - transaction: The transaction within which the data retrieval should occur.
//    /// - Returns: An optional `UnsafeRawBufferPointer` containing the data associated with the key if it exists; otherwise, `nil`.
//    /// - Throws: An `LMDBError` if the operation fails.
//    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
//    @inlinable @inline(__always)
//    public func get(atKey key: UnsafeRawBufferPointer, in transaction: Transaction) throws -> UnsafeRawBufferPointer? {
//        var key = MDB_val(.init(mutating: key))
//        var value = MDB_val()
//        return try LMDBError.nilIfNotFound {
//            try LMDBError.check(mdb_get(transaction.unsafeHandle, unsafeHandle, &key, &value))
//            return .init(value)
//        }
//    }
//
//    /// Stores a key/data pair in the database within a transaction.
//    ///
//    /// - Parameters:
//    ///   - value: The data to store, passed as `UnsafeRawBufferPointer`.
//    ///   - key: The key under which to store the data, passed as `UnsafeRawBufferPointer`.
//    ///   - overwrite: A Boolean value that determines whether to overwrite an existing value for a key. Defaults to `true`.
//    ///   - transaction: The transaction within which the data storage should occur.
//    /// - Throws: An `LMDBError` if the operation fails.
//    /// - Precondition: The transaction must be a write transaction.
//    /// - Note: If `overwrite` is set to `false` and the key already exists, the function will throw `LMDBError.keyExist`.
//    @inlinable @inline(__always)
//    public func put(_ value: UnsafeRawBufferPointer, atKey key: UnsafeRawBufferPointer, overwrite: Bool = true, in transaction: Transaction) throws {
//        var key = MDB_val(.init(mutating: key))
//        var value = MDB_val(.init(mutating: value))
//        try LMDBError.check(mdb_put(transaction.unsafeHandle, unsafeHandle, &key, &value, overwrite ? 0 : UInt32(MDB_NOOVERWRITE)))
//    }
//    
//    /// Deletes the data associated with a given key within a transaction.
//    ///
//    /// - Parameters:
//    ///   - key: The key for which to delete the data, passed as `UnsafeRawBufferPointer`.
//    ///   - value: The value to delete if the database supports sorted duplicates. If `nil`, all values for the given key will be deleted.
//    ///   - transaction: The transaction within which the deletion should occur.
//    /// - Throws: An `LMDBError` if the operation fails.
//    /// - Precondition: The transaction must be a write transaction.
//    /// - Note: If the key does not exist in the database, the function will throw `LMDBError.notFound`.
//    @inlinable @inline(__always)
//    public func delete(atKey key: UnsafeRawBufferPointer, withDuplicateValue value: UnsafeRawBufferPointer? = nil, in transaction: Transaction) throws {
//        var key = MDB_val(.init(mutating: key))
//        var value = value.map { MDB_val(.init(mutating: $0)) } ?? .init()
//        try LMDBError.check(mdb_del(transaction.unsafeHandle, unsafeHandle, &key, &value))
//    }
//}
//
//extension MDB_val {
//    /// Create a LMDB value from a buffer.
//    @inlinable @inline(__always)
//    internal init(_ buffer: UnsafeMutableRawBufferPointer) {
//        self.init(mv_size: buffer.count, mv_data: buffer.baseAddress)
//    }
//}
//extension UnsafeRawBufferPointer {
//    /// Create a buffer from a LMDB value.
//    @inlinable @inline(__always)
//    internal init(_ val: MDB_val) {
//        self.init(start: val.mv_data, count: val.mv_size)
//    }
//}
//
//// MARK: Config
//
//extension Database {
//    /// Represents the configuration for a database within an LMDB environment.
//    public struct Config: Hashable, Sendable {
//        /// Represents the sort order for keys and duplicate values in the database.
//        public enum SortOrder: Hashable, Sendable {
//            /// Sorted in standard lexicographic order.
//            case standard
//            
//            /// Sorted in reverse lexicographic order.
//            case reverse
//            
//            /// Sorted as binary integers in native byte order.
//            ///
//            /// - Note: Keys must all be the same size.
//            case integer
//        }
//        
//        /// Represents the configuration for handling duplicate keys in the database.
//        public struct DuplicateHandling: Hashable, Sendable {
//            /// The sort order for duplicate values.
//            public var sortOrder: SortOrder
//            
//            /// Indicates whether all duplicate values have the same size, allowing for further optimizations in storage and retrieval.
//            ///
//            /// - Tip: If true, cursor operations may be used to retrieve multiple items at once.
//            public var fixedSize: Bool
//            
//            /// Initializes a new configuration for handling duplicate keys.
//            /// - Parameters:
//            ///   - sortOrder: The sort order for duplicate values.
//            ///   - fixedSize: A Boolean value indicating whether all duplicate values have the same size.
//            @inlinable @inline(__always)
//            public init(sortOrder: SortOrder = .standard, fixedSize: Bool = false) {
//                self.sortOrder = sortOrder
//                self.fixedSize = fixedSize
//            }
//        }
//        
//        /// The sort order for keys in the database.
//        public var sortOrder: SortOrder
//        /// The configuration for handling duplicate keys, if duplicates are allowed.
//        ///
//        /// - Note: If duplicates are allowed, the maximum data size is limited to the maximum key size.
//        public var duplicateHandling: DuplicateHandling?
//        
//        /// Initializes a new database configuration with the specified key sorting and duplicate handling options.
//        /// - Parameters:
//        ///   - sortOrder: The sort order for keys in the database.
//        ///   - duplicateConfiguration: An optional configuration for handling duplicate keys.
//        /// - Throws: An error if an invalid configuration is provided.
//        @inlinable @inline(__always)
//        public init(sortOrder: SortOrder = .standard, duplicateHandling: DuplicateHandling? = nil) {
//            self.sortOrder = sortOrder
//            self.duplicateHandling = duplicateHandling
//        }
//    }
//}
//
//extension Database.Config.SortOrder {
//    @inlinable @inline(__always)
//    internal var rawKeyValue: Int32 {
//        switch self {
//        case .reverse:
//            return MDB_REVERSEKEY
//        case .integer:
//            return MDB_INTEGERKEY
//        case .standard:
//            return 0
//        }
//    }
//    
//    @inlinable @inline(__always)
//    internal init(rawKeyValue: Int32) {
//        if rawKeyValue & MDB_REVERSEKEY != 0 {
//            self = .reverse
//        } else if rawKeyValue & MDB_INTEGERKEY != 0 {
//            self = .integer
//        } else {
//            self = .standard
//        }
//    }
//
//    @inlinable @inline(__always)
//    internal var rawDupValue: Int32 {
//        switch self {
//        case .reverse:
//            return MDB_REVERSEDUP
//        case .integer:
//            return MDB_INTEGERDUP
//        case .standard:
//            return 0
//        }
//    }
//
//    @inlinable @inline(__always)
//    internal init(rawDupValue: Int32) {
//        if rawDupValue & MDB_REVERSEDUP != 0 {
//            self = .reverse
//        } else if rawDupValue & MDB_INTEGERDUP != 0 {
//            self = .integer
//        } else {
//            self = .standard
//        }
//    }
//}
//
//extension Database.Config.DuplicateHandling {
//    @inlinable @inline(__always)
//    internal var rawValue: Int32 {
//        MDB_DUPSORT | sortOrder.rawDupValue | (fixedSize ? MDB_DUPFIXED : 0)
//    }
//
//    @inlinable @inline(__always)
//    internal init?(rawValue: Int32) {
//        guard rawValue & MDB_DUPSORT != 0 else { return nil }
//        self.init(
//            sortOrder: Database.Config.SortOrder(rawDupValue: rawValue),
//            fixedSize: rawValue & MDB_DUPFIXED != 0
//        )
//    }
//}
//
//extension Database.Config: RawRepresentable {
//    @inlinable @inline(__always)
//    public var rawValue: Int32 {
//        sortOrder.rawKeyValue | (duplicateHandling?.rawValue ?? 0)
//    }
//
//    @inlinable @inline(__always)
//    public init(rawValue: Int32) {
//        self.init(
//            sortOrder: .init(rawKeyValue: rawValue),
//            duplicateHandling: .init(rawValue: rawValue)
//        )
//    }
//}
//
//
//// MARK: Utils
//
//extension Optional<String> {
//    @inlinable @inline(__always)
//    internal func withCStringOrNil<Result>(_ body: (UnsafePointer<Int8>?) throws -> Result) rethrows -> Result {
//        if let self {
//            try self.withCString(body)
//        } else {
//            try body(nil)
//        }
//    }
//}
