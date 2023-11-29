import CLMDB

/// An individual database in the environment.
public struct Database<KeyCoder: ByteEncoder, ValueCoder: ByteCoder> {
    /// The underlying LMDB database handle.
    @usableFromInline
    internal let unsafeHandle: MDB_dbi
    
    /// The type of `DatabaseSchema` associated with this database.
    public typealias Schema = DatabaseSchema<KeyCoder, ValueCoder>
    
    /// The `Schema` to use to encode and decode keys and values in the Database.
    public let schema: Schema
        
    /// Initializes an already open database from the given LMDB database handle.
    ///
    /// - Parameter unsafeHandle: An `MDB_dbi` representing the LMDB database handle.
    /// - Parameter schema: The `Schema` to use to encode and decode keys and values.
    @inlinable @inline(__always)
    internal init(unsafeHandle: MDB_dbi, schema: Schema) {
        self.unsafeHandle = unsafeHandle
        self.schema = schema
    }
    
    /// Opens a database in the environment, creating it if it does not already exist.
    ///
    /// - Parameters:
    ///   - name: The name of the database to open. If `nil`, the default database is used.
    ///   - config: Configuration options for the database.
    ///   - schema: Schema for encoding and decoding keys and values in the database.
    ///   - transaction: The transaction within which to open the database.
    ///
    /// - Returns: The open database.
    /// - Throws: An `LMDBError` if the database could not be opened.
    /// - Tip: You cannot open a named database unless you increased the maximum DB count for the environment.
    /// - Precondition: If the transaction is read-only, the database must already exist.
    /// - Warning: This function must not be called from multiple concurrent transactions in the same process.
    ///   A transaction that uses this function must finish (either commit or abort) before any other transaction in the process may use this function.
    @inlinable @inline(__always)
    public static func `open`(_ name: String? = nil, config: DatabaseConfig = .init(), schema: Schema, in transaction: Transaction) throws -> Database {
        try name.withCStringOrNil { name in
            var handle = MDB_dbi()
            try LMDBError.check(mdb_dbi_open(transaction.unsafeHandle, name, UInt32(config.rawValue | MDB_CREATE), &handle))
            return .init(unsafeHandle: handle, schema: schema)
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
    public func config(in transaction: Transaction) throws -> DatabaseConfig {
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
    ///   - key: The key for which to retrieve the data.
    ///   - transaction: The transaction within which the data retrieval should occur.
    /// - Returns: An optional value associated with the key if it exists; otherwise, `nil`.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
    ///   You usually don't need to worry about this, unless you're using a decoder like `RawByteCoder` that exposes the buffer.
    @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func get(atKey key: KeyCoder.Input, in transaction: Transaction) throws -> ValueCoder.Output? {
        try schema.keyCoder.withEncoding(of: key) { key in
            var key = MDB_val(.init(mutating: key))
            var value = MDB_val()
            return try LMDBError.nilIfNotFound {
                try LMDBError.check(mdb_get(transaction.unsafeHandle, unsafeHandle, &key, &value))
                return try schema.valueCoder.decoding(.init(value))
            }
        }
    }

    /// Stores a key/data pair in the database within a transaction.
    ///
    /// - Parameters:
    ///   - value: The data to store.
    ///   - key: The key under which to store the data.
    ///   - overwrite: A Boolean value that determines whether to overwrite an existing value for a key. Defaults to `true`.
    ///   - transaction: The transaction within which the data storage should occur.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Precondition: The transaction must be a write transaction.
    /// - Note: If `overwrite` is set to `false` and the key already exists, the function will throw `LMDBError.keyExist`.
    @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func put(_ value: ValueCoder.Input, atKey key: KeyCoder.Input, overwrite: Bool = true, in transaction: Transaction) throws {
        try schema.keyCoder.withEncoding(of: key) { key in
            try schema.valueCoder.withEncoding(of: value) { value in
                var key = MDB_val(.init(mutating: key))
                var value = MDB_val(.init(mutating: value))
                try LMDBError.check(mdb_put(transaction.unsafeHandle, unsafeHandle, &key, &value, overwrite ? 0 : UInt32(MDB_NOOVERWRITE)))
            }
        }
    }
    
    /// Deletes the data associated with a given key within a transaction.
    ///
    /// - Parameters:
    ///   - key: The key for which to delete the data.
    ///   - value: The value to delete if the database supports sorted duplicates. If `nil`, all values for the given key will be deleted.
    ///   - transaction: The transaction within which the deletion should occur.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Precondition: The transaction must be a write transaction.
    /// - Note: If the key does not exist in the database, the function will throw `LMDBError.notFound`.
    @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func delete(atKey key: KeyCoder.Input, value: ValueCoder.Input? = nil, in transaction: Transaction) throws {
        // FIXME: Clarify behavior if value is specified for non-DUPSORT database
        try schema.keyCoder.withEncoding(of: key) { key in
            try schema.valueCoder.withEncodingOrNil(of: value) { value in
                var key = MDB_val(.init(mutating: key))
                var value = value.map { MDB_val(.init(mutating: $0)) } ?? .init()
                try LMDBError.check(mdb_del(transaction.unsafeHandle, unsafeHandle, &key, &value))
            }
        }
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

extension Database {
    public func keyOrdering(of lhs: KeyCoder.Input, _ rhs: KeyCoder.Input, in transaction: Transaction) throws -> Ordering {
        try schema.keyCoder.withEncoding(of: lhs) { lhs in
            try schema.keyCoder.withEncoding(of: rhs) { rhs in
                var lhs = MDB_val(.init(mutating: lhs))
                var rhs = MDB_val(.init(mutating: rhs))
                return Ordering(mdb_cmp(transaction.unsafeHandle, unsafeHandle, &lhs, &rhs))
            }
        }
    }
    public func duplicateOrdering(of lhs: ValueCoder.Input, _ rhs: ValueCoder.Input, in transaction: Transaction) throws -> Ordering {
        try schema.valueCoder.withEncoding(of: lhs) { lhs in
            try schema.valueCoder.withEncoding(of: rhs) { rhs in
                var lhs = MDB_val(.init(mutating: lhs))
                var rhs = MDB_val(.init(mutating: rhs))
                return Ordering(mdb_dcmp(transaction.unsafeHandle, unsafeHandle, &lhs, &rhs))
            }
        }
    }
}

extension Database: Equatable {
    public static func ==(lhs: Database, rhs: Database) -> Bool {
        lhs.unsafeHandle == rhs.unsafeHandle
    }
}

extension Database where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder {
    public func bind<NewKeyCoder: ByteCoder, NewValueCoder: ByteCoder>(to schema: DatabaseSchema<NewKeyCoder, NewValueCoder>) -> Database<NewKeyCoder, NewValueCoder> {
        .init(unsafeHandle: unsafeHandle, schema: schema)
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
