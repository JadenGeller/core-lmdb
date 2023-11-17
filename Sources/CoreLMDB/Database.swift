import CLMDB

/// An individual database in the environment.
public struct Database {
    /// The underlying LMDB database handle.
    @usableFromInline
    internal var unsafeHandle: MDB_dbi
    
    /// Initializes an already open database from the given LMDB database handle.
    ///
    /// - Parameter unsafeHandle: An `MDB_dbi` representing the LMDB database handle.
    @inlinable @inline(__always)
    internal init(unsafeHandle: MDB_dbi) {
        self.unsafeHandle = unsafeHandle
    }
    
    /// Opens a database in the environment, creating it if it does not already exist.
    ///
    /// - Parameters:
    ///   - name: The name of the database to open. If `nil`, the default database is used.
    ///   - config: Configuration options for the database.
    ///   - transaction: The transaction within which to open the database.
    ///
    /// - Returns: The open database.
    /// - Throws: An `LMDBError` if the database could not be opened.
    /// - Tip: You cannot open a named database unless you increased the maximum DB count for the environment.
    /// - Precondition: If the transaction is read-only, the database must already exist.
    /// - Warning: This function must not be called from multiple concurrent transactions in the same process.
    ///   A transaction that uses this function must finish (either commit or abort) before any other transaction in the process may use this function.
    @inlinable @inline(__always)
    public static func `open`(_ name: String? = nil, config: Database.Config = .init(), in transaction: Transaction) throws -> Database {
        try name.withCStringOrNil { name in
            var handle = MDB_dbi()
            try LMDBError.check(mdb_dbi_open(transaction.unsafeHandle, name, UInt32(config.rawValue | MDB_CREATE), &handle))
            return .init(unsafeHandle: handle)
        }
    }
    
    /// Closes the database in the environment.
    ///
    /// - Parameter environment: The environment in which the database was opened.
    ///
    /// - Precondition: There are no open transactions that have modified the database, and no other threads will further reference the database or its cursors.
    /// - Warning: This method is not mutex protected, so improper use may corrupt the database!
    /// - Tip: It's usally better to set a larger maximum DB count for the environement.
    @inlinable @inline(__always)
    public func close(in environment: Environment) {
        LMDBError.cannotFail(mdb_dbi_close(environment.unsafeHandle, unsafeHandle))
    }
    
    /// Removes all data from the database, with an option to delete the database.
    ///
    /// - Parameters:
    ///   - close: If `true`, the database is deleted from the environment and its handle is closed. If `false`, the database is emptied but remains open and available for further operations.
    ///   - transaction: The transaction within which the database is being modified.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Precondition: If `close` is true, there are no open transactions that have modified the database, and no other threads will further reference the database or its cursors.
    /// - Warning: Closing a database is not mutex protected, so improper use may result in errors or corruption!
    @inlinable @inline(__always)
    public func drop(close: Bool, in transaction: Transaction) throws {
        try LMDBError.check(mdb_drop(transaction.unsafeHandle, unsafeHandle, close ? 1 : 0))
    }

    /// Retrieves the configuration of the database.
    ///
    /// - Parameter transaction: The transaction within which to retrieve the database configuration.
    /// - Returns: A `Database.Config` struct representing the configuration with which the database was opened.
    /// - Throws: An `LMDBError` if the configuration flags could not be retrieved.
    @inlinable @inline(__always)
    public func config(in transaction: Transaction) throws -> Database.Config {
        var rawValue: UInt32 = 0
        try LMDBError.check(mdb_dbi_flags(transaction.unsafeHandle, unsafeHandle, &rawValue))
        return .init(rawValue: Int32(rawValue))
    }
}

// MARK: Accessors

extension Database {
    /// Retrieves the data associated with a given key within a transaction.
    ///
    /// - Parameters:
    ///   - key: The key for which to retrieve the data, passed as `UnsafeRawBufferPointer`.
    ///   - transaction: The transaction within which the data retrieval should occur.
    /// - Returns: An optional `UnsafeRawBufferPointer` containing the data associated with the key if it exists; otherwise, `nil`.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
    @inlinable @inline(__always)
    public func get(atKey key: UnsafeRawBufferPointer, in transaction: Transaction) throws -> UnsafeRawBufferPointer? {
        var key = MDB_val(.init(mutating: key))
        var value = MDB_val()
        return try LMDBError.nilIfNotFound {
            try LMDBError.check(mdb_get(transaction.unsafeHandle, unsafeHandle, &key, &value))
            return .init(value)
        }
    }

    /// Stores a key/data pair in the database within a transaction.
    ///
    /// - Parameters:
    ///   - value: The data to store, passed as `UnsafeRawBufferPointer`.
    ///   - key: The key under which to store the data, passed as `UnsafeRawBufferPointer`.
    ///   - overwrite: A Boolean value that determines whether to overwrite an existing value for a key. Defaults to `true`.
    ///   - transaction: The transaction within which the data storage should occur.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Precondition: The transaction must be a write transaction.
    /// - Note: If `overwrite` is set to `false` and the key already exists, the function will throw `LMDBError.keyExist`.
    @inlinable @inline(__always)
    public func put(_ value: UnsafeRawBufferPointer, atKey key: UnsafeRawBufferPointer, overwrite: Bool = true, in transaction: Transaction) throws {
        var key = MDB_val(.init(mutating: key))
        var value = MDB_val(.init(mutating: value))
        try LMDBError.check(mdb_put(transaction.unsafeHandle, unsafeHandle, &key, &value, overwrite ? 0 : UInt32(MDB_NOOVERWRITE)))
    }
    
    /// Deletes the data associated with a given key within a transaction.
    ///
    /// - Parameters:
    ///   - key: The key for which to delete the data, passed as `UnsafeRawBufferPointer`.
    ///   - value: The value to delete if the database supports sorted duplicates. If `nil`, all values for the given key will be deleted.
    ///   - transaction: The transaction within which the deletion should occur.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Precondition: The transaction must be a write transaction.
    /// - Note: If the key does not exist in the database, the function will throw `LMDBError.notFound`.
    @inlinable @inline(__always)
    public func delete(atKey key: UnsafeRawBufferPointer, withDuplicateValue value: UnsafeRawBufferPointer? = nil, in transaction: Transaction) throws {
        var key = MDB_val(.init(mutating: key))
        var value = value.map { MDB_val(.init(mutating: $0)) } ?? .init()
        try LMDBError.check(mdb_del(transaction.unsafeHandle, unsafeHandle, &key, &value))
    }
}

extension MDB_val {
    /// Create a LMDB value from a buffer.
    @inlinable @inline(__always)
    internal init(_ buffer: UnsafeMutableRawBufferPointer) {
        self.init(mv_size: buffer.count, mv_data: buffer.baseAddress)
    }
}
extension UnsafeRawBufferPointer {
    /// Create a buffer from a LMDB value.
    @inlinable @inline(__always)
    internal init(_ val: MDB_val) {
        self.init(start: val.mv_data, count: val.mv_size)
    }
}

// MARK: Comparison

extension Database {
    public enum Ordering: Hashable, Sendable {
        case descending
        case equal
        case ascending
        
        internal init(_ value: Int32) {
            self = if value > 0 {
                .descending
            } else if value == 0 {
                .equal
            } else {
                .ascending
            }
        }
    }
    public func keyOrdering(of lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer, in transaction: Transaction) -> Ordering {
        var lhs = MDB_val(.init(mutating: lhs))
        var rhs = MDB_val(.init(mutating: rhs))
        return Ordering(mdb_cmp(transaction.unsafeHandle, unsafeHandle, &lhs, &rhs))
    }
    public func duplicateOrdering(of lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer, in transaction: Transaction) -> Ordering {
        var lhs = MDB_val(.init(mutating: lhs))
        var rhs = MDB_val(.init(mutating: rhs))
        return Ordering(mdb_dcmp(transaction.unsafeHandle, unsafeHandle, &lhs, &rhs))
    }
}

extension Database: Equatable {
    public static func ==(lhs: Database, rhs: Database) -> Bool {
        lhs.unsafeHandle == rhs.unsafeHandle
    }
}

// MARK: Config

extension Database {
    /// Represents the configuration for a database within an LMDB environment.
    public struct Config: Hashable, Sendable {
        /// Represents the sort order for keys and duplicate values in the database.
        public enum SortOrder: Hashable, Sendable {
            /// Sorted in standard lexicographic order.
            case standard
            
            /// Sorted in reverse lexicographic order.
            case reverse
            
            /// Sorted as binary integers in native byte order.
            ///
            /// - Note: Keys must all be the same size.
            case integer
        }
        
        /// Represents the configuration for handling duplicate keys in the database.
        public struct DuplicateHandling: Hashable, Sendable {
            /// The sort order for duplicate values.
            public var sortOrder: SortOrder
            
            /// Indicates whether all duplicate values have the same size, allowing for further optimizations in storage and retrieval.
            ///
            /// - Tip: If true, cursor operations may be used to retrieve multiple items at once.
            public var fixedSize: Bool
            
            /// Initializes a new configuration for handling duplicate keys.
            /// - Parameters:
            ///   - sortOrder: The sort order for duplicate values.
            ///   - fixedSize: A Boolean value indicating whether all duplicate values have the same size.
            @inlinable @inline(__always)
            public init(sortOrder: SortOrder = .standard, fixedSize: Bool = false) {
                self.sortOrder = sortOrder
                self.fixedSize = fixedSize
            }
        }
        
        /// The sort order for keys in the database.
        public var sortOrder: SortOrder
        /// The configuration for handling duplicate keys, if duplicates are allowed.
        ///
        /// - Note: If duplicates are allowed, the maximum data size is limited to the maximum key size.
        public var duplicateHandling: DuplicateHandling?
        
        /// Initializes a new database configuration with the specified key sorting and duplicate handling options.
        /// - Parameters:
        ///   - sortOrder: The sort order for keys in the database.
        ///   - duplicateConfiguration: An optional configuration for handling duplicate keys.
        /// - Throws: An error if an invalid configuration is provided.
        @inlinable @inline(__always)
        public init(sortOrder: SortOrder = .standard, duplicateHandling: DuplicateHandling? = nil) {
            self.sortOrder = sortOrder
            self.duplicateHandling = duplicateHandling
        }
    }
}

extension Database.Config.SortOrder {
    @inlinable @inline(__always)
    internal var rawKeyValue: Int32 {
        switch self {
        case .reverse:
            return MDB_REVERSEKEY
        case .integer:
            return MDB_INTEGERKEY
        case .standard:
            return 0
        }
    }
    
    @inlinable @inline(__always)
    internal init(rawKeyValue: Int32) {
        if rawKeyValue & MDB_REVERSEKEY != 0 {
            self = .reverse
        } else if rawKeyValue & MDB_INTEGERKEY != 0 {
            self = .integer
        } else {
            self = .standard
        }
    }

    @inlinable @inline(__always)
    internal var rawDupValue: Int32 {
        switch self {
        case .reverse:
            return MDB_REVERSEDUP
        case .integer:
            return MDB_INTEGERDUP
        case .standard:
            return 0
        }
    }

    @inlinable @inline(__always)
    internal init(rawDupValue: Int32) {
        if rawDupValue & MDB_REVERSEDUP != 0 {
            self = .reverse
        } else if rawDupValue & MDB_INTEGERDUP != 0 {
            self = .integer
        } else {
            self = .standard
        }
    }
}

extension Database.Config.DuplicateHandling {
    @inlinable @inline(__always)
    internal var rawValue: Int32 {
        MDB_DUPSORT | sortOrder.rawDupValue | (fixedSize ? MDB_DUPFIXED : 0)
    }

    @inlinable @inline(__always)
    internal init?(rawValue: Int32) {
        guard rawValue & MDB_DUPSORT != 0 else { return nil }
        self.init(
            sortOrder: Database.Config.SortOrder(rawDupValue: rawValue),
            fixedSize: rawValue & MDB_DUPFIXED != 0
        )
    }
}

extension Database.Config: RawRepresentable {
    @inlinable @inline(__always)
    public var rawValue: Int32 {
        sortOrder.rawKeyValue | (duplicateHandling?.rawValue ?? 0)
    }

    @inlinable @inline(__always)
    public init(rawValue: Int32) {
        self.init(
            sortOrder: .init(rawKeyValue: rawValue),
            duplicateHandling: .init(rawValue: rawValue)
        )
    }
}


// MARK: Utils

extension Optional<String> {
    @inlinable @inline(__always)
    internal func withCStringOrNil<Result>(_ body: (UnsafePointer<Int8>?) throws -> Result) rethrows -> Result {
        if let self {
            try self.withCString(body)
        } else {
            try body(nil)
        }
    }
}
